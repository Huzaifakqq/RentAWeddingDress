namespace RentAWeddingDressAPI
{
    // ✅ DI wrapper for the optional Cloudinary client.
    //    A null Cloudinary can't be constructor-injected (M.E.DI treats an
    //    unresolvable service as an error), but this holder is never null —
    //    Client == null simply means "local-disk mode" (normal local dev).
    public class CloudinaryHolder
    {
        public CloudinaryDotNet.Cloudinary Client { get; set; }
    }
}
