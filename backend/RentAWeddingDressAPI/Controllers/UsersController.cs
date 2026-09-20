using System.Linq;
using System.Web.Http;

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
    }
}