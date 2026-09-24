using System.Linq;
using System.Web.Http;
using RentAWeddingDressAPI.DTOs;

namespace RentAWeddingDressAPI.Controllers
{
    [RoutePrefix("api/users")]
    public class UsersController : ApiController
    {
        RentAWeddingDressEntities2 db = new RentAWeddingDressEntities2();

        // ✅ ADD ADDRESS
        [HttpPost]
        [Route("add-address")]
        public IHttpActionResult AddAddress(UserAddress model)
        {
            if (model == null)
                return BadRequest("Invalid data");

            db.UserAddresses.Add(model);
            db.SaveChanges();

            return Ok("Address added successfully");
        }

        // ✅ GET USER ADDRESSES
        [HttpGet]
        [Route("{userId}/addresses")]
        public IHttpActionResult GetUserAddresses(int userId)
        {
            var addresses = db.UserAddresses
                .Where(a => a.U_id == userId)
                .Select(a => new
                {
                    a.UA_id,
                    a.Address
                })
                .ToList();

            return Ok(addresses);
        }

        // ✅ SET SHOP LOCATION — one tap updates ALL dresses of this owner
        [HttpPost]
        [Route("update-shop-location")]
        public IHttpActionResult UpdateShopLocation(ShopLocationDTO model)
        {
            if (model == null)
                return BadRequest("Invalid data.");

            var dresses = db.Dresses
                .Where(d => d.U_id == model.UserId)
                .ToList();

            if (!dresses.Any())
                return BadRequest("No dresses found for this user.");

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
        public IHttpActionResult GetShopLocation(int userId)
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
