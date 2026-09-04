using System;
using Microsoft.EntityFrameworkCore.Migrations;
using NetTopologySuite.Geometries;

#nullable disable

namespace HappyPaws.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddCommunityTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:PostgresExtension:postgis", ",,");

            migrationBuilder.CreateTable(
                name: "post_likes",
                columns: table => new
                {
                    post_id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<long>(type: "bigint", nullable: false),
                    liked_at = table.Column<DateTimeOffset>(type: "timestamptz", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_post_likes", x => new { x.post_id, x.user_id });
                    table.ForeignKey(
                        name: "FK_post_likes_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "post_media",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    post_id = table.Column<Guid>(type: "uuid", nullable: false),
                    storage_key = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    cdn_url = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    mime_type = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    file_size_bytes = table.Column<int>(type: "integer", nullable: false),
                    sort_order = table.Column<short>(type: "smallint", nullable: false, defaultValue: (short)0),
                    uploaded_at = table.Column<DateTimeOffset>(type: "timestamptz", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_post_media", x => x.id);
                    table.CheckConstraint("CK_post_media_file_size", "file_size_bytes <= 5242880");
                    table.CheckConstraint("CK_post_media_mime_type", "mime_type IN ('image/jpeg','image/png','image/webp','image/heic')");
                });

            migrationBuilder.CreateTable(
                name: "posts",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    author_id = table.Column<long>(type: "bigint", nullable: false),
                    type = table.Column<string>(type: "text", nullable: false),
                    status = table.Column<string>(type: "text", nullable: false),
                    title = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    body = table.Column<string>(type: "character varying(4000)", maxLength: 4000, nullable: false),
                    like_count = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    parent_post_id = table.Column<Guid>(type: "uuid", nullable: true),
                    assigned_application_id = table.Column<Guid>(type: "uuid", nullable: true),
                    location_point = table.Column<Point>(type: "geometry(Point,4326)", nullable: true),
                    location_label = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    animal_species = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    animal_name = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: true),
                    animal_description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    is_deleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamptz", nullable: false, defaultValueSql: "now()"),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamptz", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_posts", x => x.id);
                    table.CheckConstraint("CK_posts_status", "status IN ('Active', 'Fostered', 'Assigned', 'Completed', 'PendingApproval', 'Funded', 'Rejected', 'Cancelled')");
                    table.CheckConstraint("CK_posts_type", "type IN ('RescueAlert', 'FosterUpdate', 'AdoptionListing', 'Highlight', 'TransportRequest', 'VetRequest', 'SponsorshipRequest')");
                    table.ForeignKey(
                        name: "FK_posts_posts_parent_post_id",
                        column: x => x.parent_post_id,
                        principalTable: "posts",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_posts_users_author_id",
                        column: x => x.author_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "rescue_applications",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    rescue_post_id = table.Column<Guid>(type: "uuid", nullable: false),
                    applicant_id = table.Column<long>(type: "bigint", nullable: false),
                    applicant_role = table.Column<string>(type: "text", nullable: false),
                    message = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    experience_summary = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    has_vehicle = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    status = table.Column<string>(type: "text", nullable: false),
                    poster_reviewed_at = table.Column<DateTimeOffset>(type: "timestamptz", nullable: true),
                    admin_reviewed_at = table.Column<DateTimeOffset>(type: "timestamptz", nullable: true),
                    admin_reviewer_id = table.Column<long>(type: "bigint", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamptz", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_rescue_applications", x => x.id);
                    table.CheckConstraint("CK_rescue_applications_role", "applicant_role IN ('Foster','Adopter')");
                    table.CheckConstraint("CK_rescue_applications_status", "status IN ('Pending','Approved','Rejected','AdminOverridden')");
                    table.ForeignKey(
                        name: "FK_rescue_applications_posts_rescue_post_id",
                        column: x => x.rescue_post_id,
                        principalTable: "posts",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_rescue_applications_users_admin_reviewer_id",
                        column: x => x.admin_reviewer_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_rescue_applications_users_applicant_id",
                        column: x => x.applicant_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "sponsorship_details",
                columns: table => new
                {
                    post_id = table.Column<Guid>(type: "uuid", nullable: false),
                    goal_description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    estimated_amount_lkr = table.Column<decimal>(type: "numeric(12,2)", nullable: true),
                    admin_approver_id = table.Column<long>(type: "bigint", nullable: true),
                    admin_reviewed_at = table.Column<DateTimeOffset>(type: "timestamptz", nullable: true),
                    admin_rejection_notes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    funded_at = table.Column<DateTimeOffset>(type: "timestamptz", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_sponsorship_details", x => x.post_id);
                    table.ForeignKey(
                        name: "FK_sponsorship_details_posts_post_id",
                        column: x => x.post_id,
                        principalTable: "posts",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_sponsorship_details_users_admin_approver_id",
                        column: x => x.admin_approver_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "sponsorship_proof_documents",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    post_id = table.Column<Guid>(type: "uuid", nullable: false),
                    storage_key = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    file_name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    mime_type = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    file_size_bytes = table.Column<int>(type: "integer", nullable: false),
                    uploaded_at = table.Column<DateTimeOffset>(type: "timestamptz", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_sponsorship_proof_documents", x => x.id);
                    table.CheckConstraint("CK_sponsorship_proof_file_size", "file_size_bytes <= 5242880");
                    table.CheckConstraint("CK_sponsorship_proof_mime_type", "mime_type IN ('image/jpeg','image/png','image/webp','image/heic','application/pdf')");
                    table.ForeignKey(
                        name: "FK_sponsorship_proof_documents_posts_post_id",
                        column: x => x.post_id,
                        principalTable: "posts",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "transport_tasks",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    transport_post_id = table.Column<Guid>(type: "uuid", nullable: true),
                    parent_post_id = table.Column<Guid>(type: "uuid", nullable: false),
                    requester_id = table.Column<long>(type: "bigint", nullable: false),
                    transporter_id = table.Column<long>(type: "bigint", nullable: true),
                    pickup_address = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    pickup_point = table.Column<Point>(type: "geometry(Point,4326)", nullable: false),
                    dropoff_address = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    dropoff_point = table.Column<Point>(type: "geometry(Point,4326)", nullable: false),
                    pickup_window_start = table.Column<DateTimeOffset>(type: "timestamptz", nullable: true),
                    pickup_window_end = table.Column<DateTimeOffset>(type: "timestamptz", nullable: true),
                    is_self_collection = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    status = table.Column<string>(type: "text", nullable: false),
                    completed_at = table.Column<DateTimeOffset>(type: "timestamptz", nullable: true),
                    notes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamptz", nullable: false, defaultValueSql: "now()"),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamptz", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_transport_tasks", x => x.id);
                    table.CheckConstraint("CK_transport_tasks_status", "status IN ('Open','Accepted','PickedUp','InTransit','Delivered','Completed','Cancelled')");
                    table.ForeignKey(
                        name: "FK_transport_tasks_posts_parent_post_id",
                        column: x => x.parent_post_id,
                        principalTable: "posts",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_transport_tasks_posts_transport_post_id",
                        column: x => x.transport_post_id,
                        principalTable: "posts",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_transport_tasks_users_requester_id",
                        column: x => x.requester_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_transport_tasks_users_transporter_id",
                        column: x => x.transporter_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "vet_request_details",
                columns: table => new
                {
                    post_id = table.Column<Guid>(type: "uuid", nullable: false),
                    reason_for_visit = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    clinic_name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    appointment_date = table.Column<DateTimeOffset>(type: "timestamptz", nullable: true),
                    transport_needed = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_vet_request_details", x => x.post_id);
                    table.ForeignKey(
                        name: "FK_vet_request_details_posts_post_id",
                        column: x => x.post_id,
                        principalTable: "posts",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "transport_offers",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    transport_task_id = table.Column<Guid>(type: "uuid", nullable: false),
                    transporter_id = table.Column<long>(type: "bigint", nullable: false),
                    message = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    proposed_pickup_start = table.Column<DateTimeOffset>(type: "timestamptz", nullable: false),
                    proposed_pickup_end = table.Column<DateTimeOffset>(type: "timestamptz", nullable: false),
                    status = table.Column<string>(type: "text", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamptz", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_transport_offers", x => x.id);
                    table.CheckConstraint("CK_transport_offers_status", "status IN ('Pending','Accepted','Rejected')");
                    table.ForeignKey(
                        name: "FK_transport_offers_transport_tasks_transport_task_id",
                        column: x => x.transport_task_id,
                        principalTable: "transport_tasks",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_transport_offers_users_transporter_id",
                        column: x => x.transporter_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_post_likes_user_id",
                table: "post_likes",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_post_media_post_id_sort_order",
                table: "post_media",
                columns: new[] { "post_id", "sort_order" });

            migrationBuilder.CreateIndex(
                name: "idx_posts_location",
                table: "posts",
                column: "location_point")
                .Annotation("Npgsql:IndexMethod", "gist");

            migrationBuilder.CreateIndex(
                name: "IX_posts_assigned_application_id",
                table: "posts",
                column: "assigned_application_id",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_posts_author_id_created_at",
                table: "posts",
                columns: new[] { "author_id", "created_at" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_posts_parent_post_id",
                table: "posts",
                column: "parent_post_id");

            migrationBuilder.CreateIndex(
                name: "IX_posts_type_status_created_at",
                table: "posts",
                columns: new[] { "type", "status", "created_at" },
                descending: new[] { false, false, true });

            migrationBuilder.CreateIndex(
                name: "IX_rescue_applications_admin_reviewer_id",
                table: "rescue_applications",
                column: "admin_reviewer_id");

            migrationBuilder.CreateIndex(
                name: "IX_rescue_applications_applicant_id_status",
                table: "rescue_applications",
                columns: new[] { "applicant_id", "status" });

            migrationBuilder.CreateIndex(
                name: "IX_rescue_applications_rescue_post_id_status",
                table: "rescue_applications",
                columns: new[] { "rescue_post_id", "status" });

            migrationBuilder.CreateIndex(
                name: "IX_sponsorship_details_admin_approver_id",
                table: "sponsorship_details",
                column: "admin_approver_id");

            migrationBuilder.CreateIndex(
                name: "IX_sponsorship_proof_documents_post_id",
                table: "sponsorship_proof_documents",
                column: "post_id");

            migrationBuilder.CreateIndex(
                name: "IX_transport_offers_transport_task_id_status",
                table: "transport_offers",
                columns: new[] { "transport_task_id", "status" });

            migrationBuilder.CreateIndex(
                name: "IX_transport_offers_transporter_id",
                table: "transport_offers",
                column: "transporter_id");

            migrationBuilder.CreateIndex(
                name: "IX_transport_tasks_parent_post_id",
                table: "transport_tasks",
                column: "parent_post_id");

            migrationBuilder.CreateIndex(
                name: "IX_transport_tasks_pickup_point",
                table: "transport_tasks",
                column: "pickup_point")
                .Annotation("Npgsql:IndexMethod", "gist");

            migrationBuilder.CreateIndex(
                name: "IX_transport_tasks_requester_id",
                table: "transport_tasks",
                column: "requester_id");

            migrationBuilder.CreateIndex(
                name: "IX_transport_tasks_status_created_at",
                table: "transport_tasks",
                columns: new[] { "status", "created_at" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_transport_tasks_transport_post_id",
                table: "transport_tasks",
                column: "transport_post_id");

            migrationBuilder.CreateIndex(
                name: "IX_transport_tasks_transporter_id_status",
                table: "transport_tasks",
                columns: new[] { "transporter_id", "status" });

            migrationBuilder.AddForeignKey(
                name: "FK_post_likes_posts_post_id",
                table: "post_likes",
                column: "post_id",
                principalTable: "posts",
                principalColumn: "id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_post_media_posts_post_id",
                table: "post_media",
                column: "post_id",
                principalTable: "posts",
                principalColumn: "id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_posts_rescue_applications_assigned_application_id",
                table: "posts",
                column: "assigned_application_id",
                principalTable: "rescue_applications",
                principalColumn: "id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_rescue_applications_posts_rescue_post_id",
                table: "rescue_applications");

            migrationBuilder.DropTable(
                name: "post_likes");

            migrationBuilder.DropTable(
                name: "post_media");

            migrationBuilder.DropTable(
                name: "sponsorship_details");

            migrationBuilder.DropTable(
                name: "sponsorship_proof_documents");

            migrationBuilder.DropTable(
                name: "transport_offers");

            migrationBuilder.DropTable(
                name: "vet_request_details");

            migrationBuilder.DropTable(
                name: "transport_tasks");

            migrationBuilder.DropTable(
                name: "posts");

            migrationBuilder.DropTable(
                name: "rescue_applications");

            migrationBuilder.AlterDatabase()
                .OldAnnotation("Npgsql:PostgresExtension:postgis", ",,");
        }
    }
}
