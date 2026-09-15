using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace RentAWeddingDressAPI.DTOs
{
    public class RegisterDTO
    {
        [Required]
        public string Name { get; set; }

        [Required]
        public string Contact { get; set; }

        [Required]
        public string Password { get; set; }

        [Required]
        public string ConfirmPassword { get; set; }
    }
}