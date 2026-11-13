using Microsoft.EntityFrameworkCore;

namespace RentAWeddingDressAPI
{
    // ✅ EF Core replacement for the EDMX-generated context.
    //    Same class name → controllers port over with minimal edits.
    public partial class RentAWeddingDressEntities2 : DbContext
    {
        public RentAWeddingDressEntities2(DbContextOptions<RentAWeddingDressEntities2> options)
            : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<UserAddress> UserAddresses { get; set; }
        public DbSet<Dress> Dresses { get; set; }
        public DbSet<DressCategory> DressCategories { get; set; }
        public DbSet<SubCategory> SubCategories { get; set; }
        public DbSet<Size> Sizes { get; set; }
        public DbSet<DressSize> DressSizes { get; set; }
        public DbSet<DressImage> DressImages { get; set; }
        public DbSet<DressOccasion> DressOccasions { get; set; }
        public DbSet<BookingRequest> BookingRequests { get; set; }
        public DbSet<BookingDetail> BookingDetails { get; set; }

        protected override void OnModelCreating(ModelBuilder mb)
        {
            // ── Table names exactly as they exist in SQL Server ──
            mb.Entity<User>().ToTable("Users");
            mb.Entity<UserAddress>().ToTable("UserAddress");
            mb.Entity<Dress>().ToTable("Dress");
            mb.Entity<DressCategory>().ToTable("DressCategory");
            mb.Entity<SubCategory>().ToTable("SubCategory");
            mb.Entity<Size>().ToTable("Sizes");
            mb.Entity<DressSize>().ToTable("DressSizes");
            mb.Entity<DressImage>().ToTable("DressImages");
            mb.Entity<DressOccasion>().ToTable("DressOccasion");
            mb.Entity<BookingRequest>().ToTable("BookingRequest");
            mb.Entity<BookingDetail>().ToTable("BookingDetail");

            // ── Primary keys (names don't follow the Id convention) ──
            mb.Entity<User>().HasKey(x => x.U_id);
            mb.Entity<UserAddress>().HasKey(x => x.UA_id);
            mb.Entity<Dress>().HasKey(x => x.D_id);
            mb.Entity<DressCategory>().HasKey(x => x.Category_id);
            mb.Entity<SubCategory>().HasKey(x => x.SubCategory_id);
            mb.Entity<Size>().HasKey(x => x.Size_id);
            mb.Entity<DressSize>().HasKey(x => x.DS_id);
            mb.Entity<DressImage>().HasKey(x => x.DI_id);
            mb.Entity<DressOccasion>().HasKey(x => x.Occasion_id);
            mb.Entity<BookingRequest>().HasKey(x => x.BR_id);
            mb.Entity<BookingDetail>().HasKey(x => x.BD_id);

            // ── Users ──
            mb.Entity<User>(e =>
            {
                e.Property(x => x.Role).HasMaxLength(20).IsRequired()
                    .HasDefaultValue("customer");
                e.Property(x => x.Contact).HasMaxLength(50);
                e.Property(x => x.Name).HasMaxLength(100);
                e.Property(x => x.CreditBalance).HasPrecision(10, 2);
                e.HasIndex(x => x.Contact).IsUnique();

                e.HasMany(x => x.BookingRequests).WithOne(x => x.User)
                    .HasForeignKey(x => x.U_id);
                e.HasMany(x => x.Dresses).WithOne(x => x.User)
                    .HasForeignKey(x => x.U_id);
                e.HasMany(x => x.UserAddresses).WithOne(x => x.User)
                    .HasForeignKey(x => x.U_id);
            });

            // ── UserAddress ──
            mb.Entity<UserAddress>(e =>
            {
                e.Property(x => x.Latitude).HasPrecision(9, 6);
                e.Property(x => x.Longitude).HasPrecision(9, 6);
                e.HasOne(x => x.User).WithMany(x => x.UserAddresses)
                    .HasForeignKey(x => x.U_id);
                e.HasMany(x => x.BookingRequests).WithOne(x => x.UserAddress)
                    .HasForeignKey(x => x.UserAddressID);
            });

            // ── Dress ──
            mb.Entity<Dress>(e =>
            {
                e.Property(x => x.RentPrice).HasPrecision(18, 2);
                e.Property(x => x.Latitude).HasPrecision(9, 6);
                e.Property(x => x.Longitude).HasPrecision(9, 6);
                e.HasOne(x => x.User).WithMany(x => x.Dresses)
                    .HasForeignKey(x => x.U_id);
                e.HasOne(x => x.DressCategory).WithMany(x => x.Dresses)
                    .HasForeignKey(x => x.Category_id);
                e.HasOne(x => x.SubCategory).WithMany(x => x.Dresses)
                    .HasForeignKey(x => x.SubCategory_id);
                e.HasMany(x => x.BookingDetails).WithOne(x => x.Dress)
                    .HasForeignKey(x => x.D_id);
                e.HasMany(x => x.DressImages).WithOne(x => x.Dress)
                    .HasForeignKey(x => x.D_id);
                e.HasMany(x => x.DressOccasions).WithOne(x => x.Dress)
                    .HasForeignKey(x => x.D_id);
                e.HasMany(x => x.DressSizes).WithOne(x => x.Dress)
                    .HasForeignKey(x => x.D_id);
            });

            // ── Category / SubCategory ──
            mb.Entity<DressCategory>(e =>
            {
                e.Property(x => x.Cname).HasMaxLength(100);
                e.HasMany(x => x.Dresses).WithOne(x => x.DressCategory)
                    .HasForeignKey(x => x.Category_id);
                e.HasMany(x => x.SubCategories).WithOne(x => x.DressCategory)
                    .HasForeignKey(x => x.Category_id);
            });

            mb.Entity<SubCategory>(e =>
            {
                e.Property(x => x.SCname).HasMaxLength(100);
                e.HasOne(x => x.DressCategory).WithMany(x => x.SubCategories)
                    .HasForeignKey(x => x.Category_id);
            });

            // ── Sizes / DressSizes / DressImages / DressOccasion ──
            mb.Entity<Size>(e =>
            {
                e.Property(x => x.SizeName).HasMaxLength(50);
                e.HasMany(x => x.DressSizes).WithOne(x => x.Size)
                    .HasForeignKey(x => x.Size_id);
            });

            mb.Entity<DressSize>(e =>
            {
                e.HasOne(x => x.Dress).WithMany(x => x.DressSizes)
                    .HasForeignKey(x => x.D_id);
                e.HasOne(x => x.Size).WithMany(x => x.DressSizes)
                    .HasForeignKey(x => x.Size_id);
            });

            mb.Entity<DressImage>(e =>
            {
                e.HasOne(x => x.Dress).WithMany(x => x.DressImages)
                    .HasForeignKey(x => x.D_id);
            });

            mb.Entity<DressOccasion>(e =>
            {
                e.HasOne(x => x.Dress).WithMany(x => x.DressOccasions)
                    .HasForeignKey(x => x.D_id);
            });

            // ── Bookings ──
            mb.Entity<BookingRequest>(e =>
            {
                e.Property(x => x.PenaltyAmount).HasPrecision(10, 2);
                e.Property(x => x.Status).HasDefaultValue(0);
                e.HasOne(x => x.User).WithMany(x => x.BookingRequests)
                    .HasForeignKey(x => x.U_id);
                e.HasOne(x => x.UserAddress).WithMany(x => x.BookingRequests)
                    .HasForeignKey(x => x.UserAddressID);
                // Rider: FK to Users with NO navigation property (same as EDMX)
                e.HasOne<User>().WithMany().HasForeignKey(x => x.Rider_id);
            });

            mb.Entity<BookingDetail>(e =>
            {
                e.Property(x => x.TotalPrice).HasPrecision(18, 2);
                e.HasOne(x => x.BookingRequest).WithMany(x => x.BookingDetails)
                    .HasForeignKey(x => x.BR_id);
                e.HasOne(x => x.Dress).WithMany(x => x.BookingDetails)
                    .HasForeignKey(x => x.D_id);
            });
        }
    }
}
