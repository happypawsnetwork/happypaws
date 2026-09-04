using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HappyPaws.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class DetectPendingChanges : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "lifestyle_has_cats",
                table: "users");

            migrationBuilder.DropColumn(
                name: "lifestyle_has_dogs",
                table: "users");

            migrationBuilder.DropColumn(
                name: "expectations_good_with_cats",
                table: "posts");

            migrationBuilder.DropColumn(
                name: "expectations_good_with_dogs",
                table: "posts");

            migrationBuilder.RenameColumn(
                name: "lifestyle_activity_level",
                table: "users",
                newName: "lifestyle_home_size");

            migrationBuilder.RenameColumn(
                name: "expectations_activity_level",
                table: "posts",
                newName: "expectations_home_size");

            migrationBuilder.AddColumn<string>(
                name: "lifestyle_activity_tempo",
                table: "users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<List<string>>(
                name: "lifestyle_existing_pets",
                table: "users",
                type: "text[]",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "expectations_activity_tempo",
                table: "posts",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<List<string>>(
                name: "expectations_good_with_pets",
                table: "posts",
                type: "text[]",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "lifestyle_activity_tempo",
                table: "users");

            migrationBuilder.DropColumn(
                name: "lifestyle_existing_pets",
                table: "users");

            migrationBuilder.DropColumn(
                name: "expectations_activity_tempo",
                table: "posts");

            migrationBuilder.DropColumn(
                name: "expectations_good_with_pets",
                table: "posts");

            migrationBuilder.RenameColumn(
                name: "lifestyle_home_size",
                table: "users",
                newName: "lifestyle_activity_level");

            migrationBuilder.RenameColumn(
                name: "expectations_home_size",
                table: "posts",
                newName: "expectations_activity_level");

            migrationBuilder.AddColumn<bool>(
                name: "lifestyle_has_cats",
                table: "users",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "lifestyle_has_dogs",
                table: "users",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "expectations_good_with_cats",
                table: "posts",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "expectations_good_with_dogs",
                table: "posts",
                type: "boolean",
                nullable: true);
        }
    }
}
