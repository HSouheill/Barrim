// Migration script to add status field to users collection
// Run this script to update existing user documents

db = db.getSiblingDB('barrim'); // Replace with your database name

print("Starting user status migration...");

// Update all users to have a status field based on their isActive field
const result = db.users.updateMany(
  { status: { $exists: false } }, // Only update documents that don't have status field
  [
    {
      $set: {
        status: {
          $cond: {
            if: { $eq: ["$isActive", true] },
            then: "active",
            else: "inactive"
          }
        }
      }
    }
  ]
);

print("Migration completed!");
print("Documents matched: " + result.matchedCount);
print("Documents modified: " + result.modifiedCount);

// Verify the migration
const usersWithoutStatus = db.users.countDocuments({ status: { $exists: false } });
print("Users without status field after migration: " + usersWithoutStatus);

if (usersWithoutStatus === 0) {
  print("✅ Migration successful - all users now have status field");
} else {
  print("❌ Migration incomplete - some users still missing status field");
} 