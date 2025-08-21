// Migration script to move wholesaler branches from separate collection to embedded format
// Run this script in MongoDB shell or as a Node.js script

db = db.getSiblingDB('barrim');

print("Starting migration of wholesaler branches...");

// Get all wholesaler branches
const branches = db.wholesaler_branches.find({}).toArray();

print(`Found ${branches.length} branches to migrate`);

branches.forEach(branch => {
    // Find the corresponding wholesaler
    const wholesaler = db.wholesalers.findOne({ _id: branch.wholesalerId });
    
    if (wholesaler) {
        // Convert WholesalerBranch to Branch format
        const embeddedBranch = {
            _id: branch._id,
            name: branch.name,
            location: branch.location,
            phone: branch.phone,
            category: branch.category,
            subCategory: branch.subCategory,
            description: branch.description,
            images: branch.images || [],
            videos: branch.videos || [],
            status: branch.status || "pending",
            createdAt: branch.createdAt,
            updatedAt: branch.updatedAt
        };
        
        // Add the branch to the wholesaler's branches array
        const result = db.wholesalers.updateOne(
            { _id: branch.wholesalerId },
            { $push: { branches: embeddedBranch } }
        );
        
        if (result.modifiedCount > 0) {
            print(`Successfully migrated branch ${branch._id} for wholesaler ${branch.wholesalerId}`);
        } else {
            print(`Failed to migrate branch ${branch._id} for wholesaler ${branch.wholesalerId}`);
        }
    } else {
        print(`Wholesaler ${branch.wholesalerId} not found for branch ${branch._id}`);
    }
});

print("Migration completed!");

// Optional: Drop the old collection after verifying migration
// db.wholesaler_branches.drop(); 