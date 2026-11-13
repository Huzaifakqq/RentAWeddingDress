using Microsoft.AspNetCore.Mvc;
using RentAWeddingDressAPI.DTOs;

namespace RentAWeddingDressAPI.Controllers
{
    // ✅ Ported from Web API 2 → ASP.NET Core.
    //    Route/JSON/behavior kept identical so the Flutter app can't tell the difference.
    [Route("api/auth")]
    public class AuthController : ControllerBase
    {
        private readonly RentAWeddingDressEntities2 db;

        public AuthController(RentAWeddingDressEntities2 context)
        {
            db = context;
        }

        [HttpPost]
        [Route("register")]
        public ActionResult Register([FromBody] RegisterDTO model)
        {
            // 1️⃣ Check Model Validation
            if (!ModelState.IsValid)
                return BadRequest(new { Message = "All fields are required" });

            // 2️⃣ Check Password Match
            if (model.Password != model.ConfirmPassword)
                return BadRequest(new { Message = "Passwords do not match" });

            // 3️⃣ Check if User Already Exists
            var existingUser = db.Users.FirstOrDefault(x => x.Contact == model.Contact);
            if (existingUser != null)
                return BadRequest(new { Message = "User already exists" });

            // 4️⃣ Create New User
            User newUser = new User()
            {
                Name = model.Name,
                Contact = model.Contact,
                Password = model.Password,
                // ✅ Rider registration via the signup toggle; everyone else is a customer
                Role = string.IsNullOrWhiteSpace(model.Role) ? "customer" : model.Role.Trim().ToLower()
            };

            db.Users.Add(newUser);
            db.SaveChanges();

            return Ok("Account Created Successfully");
        }

        //LOGIN
        [HttpPost]
        [Route("login")]
        public ActionResult Login([FromBody] LoginDTO model)
        {
            // 1️⃣ Validate input
            if (!ModelState.IsValid)
                return BadRequest(new { Message = "Contact and Password are required" });

            // 2️⃣ Check if user exists
            var user = db.Users
                         .FirstOrDefault(x => x.Contact == model.Contact
                                           && x.Password == model.Password);

            if (user == null)
                return BadRequest(new { Message = "Invalid Contact or Password" });

            // ✅ Role mode check: the login screen says which role is logging in
            string userRole = string.IsNullOrWhiteSpace(user.Role) ? "customer" : user.Role.ToLower();

            if (!string.IsNullOrWhiteSpace(model.Role))
            {
                string requestedRole = model.Role.Trim().ToLower();

                if (userRole != requestedRole)
                    return BadRequest(new { Message = requestedRole == "rider"
                        ? "This is not a rider account"
                        : "This is not a customer account" });
            }

            // 3️⃣ Return Success Response
            return Ok(new
            {
                Message = "Login Successful",
                UserId = user.U_id,
                Name = user.Name,
                Contact = user.Contact,
                Role = userRole
            });
        }
    }
}
