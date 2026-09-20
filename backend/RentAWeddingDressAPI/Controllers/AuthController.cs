using RentAWeddingDressAPI.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;


namespace RentAWeddingDressAPI.Controllers
{
    [RoutePrefix("api/auth")]
    public class AuthController : ApiController
    {
        RentAWeddingDressEntities2 db = new RentAWeddingDressEntities2();

        [HttpPost]
        [Route("register")]
        public IHttpActionResult Register(RegisterDTO model)
        {
            // 1️⃣ Check Model Validation
            if (!ModelState.IsValid)
                return BadRequest("All fields are required");

            // 2️⃣ Check Password Match
            if (model.Password != model.ConfirmPassword)
                return BadRequest("Passwords do not match");

            // 3️⃣ Check if User Already Exists
            var existingUser = db.Users.FirstOrDefault(x => x.Contact == model.Contact);
            if (existingUser != null)
                return BadRequest("User already exists");

            // 4️⃣ Create New User
            User newUser = new User()
            {
                Name = model.Name,
                Contact = model.Contact,
                Password = model.Password
            };

            db.Users.Add(newUser);
            db.SaveChanges();

            return Ok("Account Created Successfully");
        }
        //LOGIN
        [HttpPost]
        [Route("login")]
        public IHttpActionResult Login(LoginDTO model)
        {
            // 1️⃣ Validate input
            if (!ModelState.IsValid)
                return BadRequest("Contact and Password are required");

            // 2️⃣ Check if user exists
            var user = db.Users
                         .FirstOrDefault(x => x.Contact == model.Contact
                                           && x.Password == model.Password);

            if (user == null)
                return BadRequest("Invalid Contact or Password");

            // 3️⃣ Return Success Response
            return Ok(new
            {
                Message = "Login Successful",
                UserId = user.U_id,
                Name = user.Name,
                Contact = user.Contact
            });
        }
    }
    }
