using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HappyPaws.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddUserAddressAndLocation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "address_line1",
                table: "users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "address_line2",
                table: "users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "city",
                table: "users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "country",
                table: "users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "home_latitude",
                table: "users",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "home_longitude",
                table: "users",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "postal_code",
                table: "users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "state",
                table: "users",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "address_line1",
                table: "users");

            migrationBuilder.DropColumn(
                name: "address_line2",
                table: "users");

            migrationBuilder.DropColumn(
                name: "city",
                table: "users");

            migrationBuilder.DropColumn(
                name: "country",
                table: "users");

            migrationBuilder.DropColumn(
                name: "home_latitude",
                table: "users");

            migrationBuilder.DropColumn(
                name: "home_longitude",
                table: "users");

            migrationBuilder.DropColumn(
                name: "postal_code",
                table: "users");

            migrationBuilder.DropColumn(
                name: "state",
                table: "users");
        }
    }
}
