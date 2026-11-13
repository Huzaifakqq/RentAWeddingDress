using Microsoft.AspNetCore.Mvc;
using RentAWeddingDressAPI.DTOs;

namespace RentAWeddingDressAPI.Controllers
{
    // ✅ Ported from Web API 2 → ASP.NET Core (same routes + JSON)
    [Route("api/users")]
    public class UsersController : ControllerBase
    {
        private readonly RentAWeddingDressEntities2 db;

        public UsersController(RentAWeddingDressEntities2 context)
        {
            db = context;
        }

        // ✅ ADD ADDRESS
        [HttpPost]
        [Route("add-address")]
        public ActionResult AddAddress([FromBody] UserAddress model)
        {
            if (model == null)
                return BadRequest(new { Message = "Invalid data" });

            db.UserAddresses.Add(model);
            db.SaveChanges();

            return Ok("Address added successfully");
        }

        // ✅ GET USER ADDRESSES (includes map pin)
        [HttpGet]
        [Route("{userId}/addresses")]
        public ActionResult GetUserAddresses(int userId)
        {
            var addresses = db.UserAddresses
                .Where(a => a.U_id == userId)
                .Select(a => new
                {
                    a.UA_id,
                    a.Address,
                    Latitude = (double?)a.Latitude,
                    Longitude = (double?)a.Longitude
                })
                .ToList();

            return Ok(addresses);
        }

        // ✅ SET SHOP LOCATION — one tap updates ALL dresses of this owner
        [HttpPost]
        [Route("update-shop-location")]
        public ActionResult UpdateShopLocation([FromBody] ShopLocationDTO model)
        {
            if (model == null)
                return BadRequest(new { Message = "Invalid data." });

            var dresses = db.Dresses
                .Where(d => d.U_id == model.UserId)
                .ToList();

            if (!dresses.Any())
                return BadRequest(new { Message = "No dresses found for this user." });

            decimal lat = (decimal)model.Latitude;
            decimal lng = (decimal)model.Longitude;

            foreach (var dress in dresses)
            {
                dress.Latitude = lat;
                dress.Longitude = lng;
            }

            db.SaveChanges();

            return Ok(new
            {
                Message = "Shop location updated for all dresses.",
                Count = dresses.Count
            });
        }

        // ✅ GET CURRENT SHOP LOCATION (first dress that has one)
        [HttpGet]
        [Route("shop-location/{userId}")]
        public ActionResult GetShopLocation(int userId)
        {
            var dress = db.Dresses
                .Where(d => d.U_id == userId &&
                            d.Latitude != null && d.Longitude != null)
                .FirstOrDefault();

            if (dress == null)
                return Ok(new { Latitude = (double?)null, Longitude = (double?)null });

            return Ok(new
            {
                Latitude = (double?)dress.Latitude,
                Longitude = (double?)dress.Longitude
            });
        }
    }
}
