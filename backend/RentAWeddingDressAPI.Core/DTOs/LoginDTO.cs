using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace RentAWeddingDressAPI.DTOs
{
    public class LoginDTO
    {
        [Required]
        public string Contact { get; set; }

        [Required]
        public string Password { get; set; }

        // ✅ Role mode selected on the login screen ("customer" or "rider").
        //    Null/empty = don't check (backward compatible).
        public string Role { get; set; }
    }
}