using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HappyPaws.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddLifestyleProfile : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "lifestyle_activity_level",
                table: "users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "lifestyle_has_cats",
                table: "users",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "lifestyle_has_children",
                table: "users",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "lifestyle_has_dogs",
                table: "users",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "lifestyle_has_yard",
                table: "users",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "expectations_activity_level",
                table: "posts",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "expectations_good_with_cats",
                table: "posts",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "expectations_good_with_children",
                table: "posts",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "expectations_good_with_dogs",
                table: "posts",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "expectations_requires_yard",
                table: "posts",
                type: "boolean",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "lifestyle_activity_level",
                table: "users");

            migrationBuilder.DropColumn(
                name: "lifestyle_has_cats",
                table: "users");

            migrationBuilder.DropColumn(
                name: "lifestyle_has_children",
                table: "users");

            migrationBuilder.DropColumn(
                name: "lifestyle_has_dogs",
                table: "users");

            migrationBuilder.DropColumn(
                name: "lifestyle_has_yard",
                table: "users");

            migrationBuilder.DropColumn(
                name: "expectations_activity_level",
                table: "posts");

            migrationBuilder.DropColumn(
                name: "expectations_good_with_cats",
                table: "posts");

            migrationBuilder.DropColumn(
                name: "expectations_good_with_children",
                table: "posts");

            migrationBuilder.DropColumn(
                name: "expectations_good_with_dogs",
                table: "posts");

            migrationBuilder.DropColumn(
                name: "expectations_requires_yard",
                table: "posts");
        }
    }
}
