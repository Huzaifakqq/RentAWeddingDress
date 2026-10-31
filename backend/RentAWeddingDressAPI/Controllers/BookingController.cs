using RentAWeddingDressAPI.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace RentAWeddingDressAPI.Controllers
{
    [RoutePrefix("api/bookings")]
    public class BookingController : ApiController
    {
        // Supervisor credit system: cancel OR reschedule within the last
        // 4 days before delivery → 20% of the booking total is deducted
        // from the customer's credit balance (Users.CreditBalance).
        private const decimal PenaltyRate = 0.20m;
        private const int PenaltyThresholdDays = 4;

        RentAWeddingDressEntities2 db = new RentAWeddingDressEntities2();

        // ✅ CHECK AVAILABILITY (multi-size)
        [HttpPost]
        [Route("check")]
        public IHttpActionResult CheckAvailability(CheckAvailabilityDTO model)
        {
            if (model == null || model.Items == null || !model.Items.Any())
                return BadRequest("Select at least one size.");

            if (model.StartDate > model.EndDate)
                return BadRequest("End date must be greater than start date.");

            var dress = db.Dresses.FirstOrDefault(d => d.D_id == model.DressId);
            if (dress == null)
                return NotFound();

            int numberOfDays = (model.EndDate - model.StartDate).Days + 1;
            int totalQty = 0;
            var problems = new List<string>();

            foreach (var item in model.Items)
            {
                if (item.Quantity <= 0) continue;

                var dressSize = db.DressSizes.FirstOrDefault(ds =>
                    ds.D_id == model.DressId && ds.Size_id == item.SizeId);

                if (dressSize == null)
                {
                    problems.Add("Size not found.");
                    continue;
                }

                int totalStock = dressSize.Stock ?? 1;

                int bookedQty = db.BookingDetails
                    .Where(bd => bd.D_id == model.DressId &&
                                 bd.Size_id == item.SizeId &&
                                 bd.BookingRequest.Status != 2 &&
                                 bd.BookingRequest.Status != 3 &&
                                 bd.BookingRequest.StartingDate <= model.EndDate &&
                                 bd.BookingRequest.ReturnDate >= model.StartDate)
                    .Sum(bd => (int?)bd.Quantity) ?? 0;

                int available = totalStock - bookedQty;

                if (item.Quantity > available)
                {
                    string sizeName = db.Sizes
                        .Where(s => s.Size_id == item.SizeId)
                        .Select(s => s.SizeName)
                        .FirstOrDefault() ?? "?";

                    problems.Add($"Only {available} available in size {sizeName}.");
                }

                totalQty += item.Quantity;
            }

            decimal totalCost = dress.RentPrice * numberOfDays * totalQty;

            if (problems.Any())
            {
                return Ok(new AvailabilityResponseDTO
                {
                    IsAvailable = false,
                    NumberOfDays = numberOfDays,
                    RentPerDay = dress.RentPrice,
                    TotalCost = totalCost,
                    Message = string.Join(" ", problems)
                });
            }

            return Ok(new AvailabilityResponseDTO
            {
                IsAvailable = true,
                NumberOfDays = numberOfDays,
                RentPerDay = dress.RentPrice,
                TotalCost = totalCost,
                Message = "Selected sizes are available."
            });
        }

        // ✅ CONFIRM BOOKING (multi-size, one order = many BookingDetails)
        [HttpPost]
        [Route("confirm")]
        public IHttpActionResult ConfirmBooking(ConfirmBookingDTO model)
        {
            if (model == null || model.Items == null || !model.Items.Any(i => i.Quantity > 0))
                return BadRequest("Select at least one size.");

            if (model.StartDate > model.EndDate)
                return BadRequest("Invalid date selection.");

            var dress = db.Dresses.FirstOrDefault(d => d.D_id == model.DressId);
            if (dress == null)
                return NotFound();

            int numberOfDays = (model.EndDate - model.StartDate).Days + 1;
            decimal orderTotal = 0;
            var validatedItems = new List<BookingItemDTO>();

            // ✅ Validate stock for every size line
            foreach (var item in model.Items)
            {
                if (item.Quantity <= 0) continue;

                var dressSize = db.DressSizes.FirstOrDefault(ds =>
                    ds.D_id == model.DressId && ds.Size_id == item.SizeId);

                if (dressSize == null)
                    return BadRequest("Selected size is not available.");

                int totalStock = dressSize.Stock ?? 1;
                int bookedQty = db.BookingDetails
                    .Where(bd => bd.D_id == model.DressId &&
                                 bd.Size_id == item.SizeId &&
                                 bd.BookingRequest.Status != 2 &&
                                 bd.BookingRequest.Status != 3 &&
                                 bd.BookingRequest.StartingDate <= model.EndDate &&
                                 bd.BookingRequest.ReturnDate >= model.StartDate)
                    .Sum(bd => (int?)bd.Quantity) ?? 0;

                int available = totalStock - bookedQty;

                if (item.Quantity > available)
                    return BadRequest($"Only {available} available in the selected size.");

                orderTotal += dress.RentPrice * numberOfDays * item.Quantity;
                validatedItems.Add(item);
            }

            if (!validatedItems.Any())
                return BadRequest("Select at least one size.");

            // ✅ Check credit balance
            var customer = db.Users.Find(model.UserId);
            if (customer == null)
                return BadRequest("User not found.");

            // ✅ Save delivery pin (from Google Maps) onto the chosen address
            var userAddress = db.UserAddresses.Find(model.UserAddressId);
            if (userAddress == null || userAddress.U_id != model.UserId)
                return BadRequest("Address not found.");

            if (model.Latitude.HasValue && model.Longitude.HasValue)
            {
                userAddress.Latitude = (decimal)model.Latitude.Value;
                userAddress.Longitude = (decimal)model.Longitude.Value;
            }

            decimal creditBalance = customer.CreditBalance ?? 0;
            decimal creditPenalty = 0;
            decimal finalTotal = orderTotal;

            if (creditBalance < 0)
            {
                creditPenalty = Math.Abs(creditBalance);
                finalTotal = orderTotal + creditPenalty;
            }

            var bookingRequest = new BookingRequest
            {
                U_id = model.UserId,
                UserAddressID = model.UserAddressId,
                StartingDate = model.StartDate,
                ReturnDate = model.EndDate,
                NoOfDays = numberOfDays,
                Status = 0,
                PenaltyAmount = creditPenalty
            };

            db.BookingRequests.Add(bookingRequest);
            db.SaveChanges();

            // ✅ One BookingDetail per size (2 medium + 1 small + 4 XL = 3 rows)
            foreach (var item in validatedItems)
            {
                db.BookingDetails.Add(new BookingDetail
                {
                    BR_id = bookingRequest.BR_id,
                    D_id = model.DressId,
                    Size_id = item.SizeId,
                    Quantity = item.Quantity,
                    TotalPrice = dress.RentPrice * numberOfDays * item.Quantity
                });
            }

            db.SaveChanges();

            // ✅ Clear credit if penalty was included
            if (creditPenalty > 0)
            {
                customer.CreditBalance = 0;
                db.SaveChanges();
            }

            return Ok(new
            {
                Message = "Booking confirmed successfully.",
                BookingId = bookingRequest.BR_id,
                OrderTotal = orderTotal,
                Penalty = creditPenalty,
                FinalTotal = finalTotal
            });
        }

        // ✅ CANCEL BOOKING (anytime; penalty shown but Rs. 0 for now)
        [HttpPost]
        [Route("cancel")]
        public IHttpActionResult CancelBooking(CancelBookingDTO model)
        {
            var booking = db.BookingRequests
                            .FirstOrDefault(b => b.BR_id == model.BookingId);

            if (booking == null)
                return NotFound();

            if (booking.U_id != model.UserId)
                return BadRequest("This booking does not belong to you.");

            if (booking.Status != 0 && booking.Status != 1)
                return BadRequest("Cannot cancel at this stage.");

            int daysBeforeDelivery = (booking.StartingDate - DateTime.Now).Days;
            decimal orderTotal = booking.BookingDetails.Sum(d => d.TotalPrice);

            // 20% of booking total when delivery is 4 days away or less.
            decimal penalty = 0;
            bool hasPenalty = daysBeforeDelivery <= PenaltyThresholdDays;

            if (hasPenalty)
            {
                penalty = orderTotal * PenaltyRate;

                if (penalty > 0)
                {
                    var user = db.Users.Find(model.UserId);
                    user.CreditBalance = (user.CreditBalance ?? 0) - penalty;
                }
            }

            booking.Status = 2;
            booking.CancelledDate = DateTime.Now;
            booking.PenaltyAmount = penalty;

            // No stock restore needed: availability = Stock - active bookings.

            db.SaveChanges();

            return Ok(new
            {
                Message = hasPenalty && penalty > 0
                    ? "Booking cancelled. Rs."
                      + penalty.ToString("0")
                      + " late-cancellation charge (20%) deducted from credit."
                    : "Booking cancelled.",
                Penalty = penalty,
                HasPenalty = hasPenalty,
                DaysBefore = daysBeforeDelivery
            });
        }

        // ✅ RESCHEDULE BOOKING (anytime; penalty shown but Rs. 0 for now)
        [HttpPost]
        [Route("reschedule")]
        public IHttpActionResult RescheduleBooking(RescheduleDTO model)
        {
            if (model == null)
                return BadRequest("Invalid data.");

            if (model.StartDate > model.EndDate)
                return BadRequest("End date must be greater than start date.");

            var booking = db.BookingRequests
                            .FirstOrDefault(b => b.BR_id == model.BookingId);

            if (booking == null)
                return NotFound();

            if (booking.U_id != model.UserId)
                return BadRequest("This booking does not belong to you.");

            if (booking.Status != 0 && booking.Status != 1)
                return BadRequest("Cannot reschedule at this stage.");

            int daysBeforeDelivery = (booking.StartingDate - DateTime.Now).Days;
            bool hasPenalty = daysBeforeDelivery <= PenaltyThresholdDays;

            // ✅ Original booking total — the 20% charge is based on this,
            //    not on the new dates the user is switching to.
            decimal originalTotal = booking.BookingDetails.Sum(d => d.TotalPrice);

            int newNoOfDays = (model.EndDate - model.StartDate).Days + 1;

            // ✅ Re-check stock for new dates on every size line
            foreach (var item in booking.BookingDetails)
            {
                if (item.Size_id == null) continue;

                int totalStock = db.DressSizes
                    .Where(ds => ds.D_id == item.D_id && ds.Size_id == item.Size_id)
                    .Select(ds => (int?)(ds.Stock ?? 1))
                    .FirstOrDefault() ?? 1;

                int bookedQty = db.BookingDetails
                    .Where(bd => bd.D_id == item.D_id &&
                                 bd.Size_id == item.Size_id &&
                                 bd.BR_id != booking.BR_id &&
                                 bd.BookingRequest.Status != 2 &&
                                 bd.BookingRequest.Status != 3 &&
                                 bd.BookingRequest.StartingDate <= model.EndDate &&
                                 bd.BookingRequest.ReturnDate >= model.StartDate)
                    .Sum(bd => (int?)bd.Quantity) ?? 0;

                int available = totalStock - bookedQty;
                int qty = item.Quantity ?? 1;

                if (qty > available)
                {
                    string sizeName = db.Sizes
                        .Where(s => s.Size_id == item.Size_id)
                        .Select(s => s.SizeName)
                        .FirstOrDefault() ?? "?";

                    return BadRequest($"Not enough stock in size {sizeName} for new dates.");
                }

                decimal rentPerDay = db.Dresses
                    .Where(d => d.D_id == item.D_id)
                    .Select(d => d.RentPrice)
                    .FirstOrDefault();

                item.TotalPrice = rentPerDay * newNoOfDays * qty;
            }

            decimal penalty = hasPenalty ? originalTotal * PenaltyRate : 0;

            if (penalty > 0)
            {
                var user = db.Users.Find(model.UserId);
                user.CreditBalance = (user.CreditBalance ?? 0) - penalty;
            }

            booking.StartingDate = model.StartDate;
            booking.ReturnDate = model.EndDate;
            booking.NoOfDays = newNoOfDays;
            booking.PenaltyAmount = penalty;
            booking.CancelledDate = null;

            db.SaveChanges();

            return Ok(new
            {
                Message = penalty > 0
                    ? "Booking rescheduled. Rs."
                      + penalty.ToString("0")
                      + " late-reschedule charge (20%) deducted from credit."
                    : "Booking rescheduled.",
                Penalty = penalty,
                HasPenalty = hasPenalty,
                DaysBefore = daysBeforeDelivery
            });
        }

        // ✅ GET CUSTOMER CREDIT
        [HttpGet]
        [Route("credit/{userId}")]
        public IHttpActionResult GetCredit(int userId)
        {
            var user = db.Users.Find(userId);
            if (user == null)
                return NotFound();

            return Ok(new
            {
                CreditBalance = user.CreditBalance ?? 0
            });
        }

        // ✅ GET BOOKED DATE RANGES FOR A DRESS (blocks calendar days)
        // excludeBookingId: skip this booking's own dates (e.g. when rescheduling it)
        [HttpGet]
        [Route("booked-dates/{dressId}")]
        public IHttpActionResult GetBookedDates(int dressId, int? excludeBookingId = null)
        {
            var query = db.BookingDetails
                .Where(bd => bd.D_id == dressId &&
                             bd.BookingRequest.Status != 2 &&
                             bd.BookingRequest.Status != 3)
                .Select(bd => new
                {
                    bd.BookingRequest.BR_id,
                    Start = bd.BookingRequest.StartingDate,
                    End = bd.BookingRequest.ReturnDate
                });

            if (excludeBookingId.HasValue)
                query = query.Where(x => x.BR_id != excludeBookingId.Value);

            var ranges = query
                .ToList()
                .GroupBy(x => new { x.Start, x.End })
                .Select(g => new
                {
                    Start = g.Key.Start.ToString("yyyy-MM-dd"),
                    End = g.Key.End.ToString("yyyy-MM-dd")
                })
                .ToList();

            return Ok(ranges);
        }
    }
}
