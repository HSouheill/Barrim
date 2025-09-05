// Migration script to unify service provider IDs in reviews
// This script updates existing reviews to use user IDs instead of separate service provider IDs

const { MongoClient } = require('mongodb');

async function migrateReviewServiceProviderIds() {
    const client = new MongoClient('mongodb://localhost:27017');
    
    try {
        await client.connect();
        console.log('Connected to MongoDB');
        
        const db = client.db('barrim');
        const reviewsCollection = db.collection('reviews');
        const usersCollection = db.collection('users');
        const serviceProvidersCollection = db.collection('serviceProviders');
        
        // Get all reviews
        const reviews = await reviewsCollection.find({}).toArray();
        console.log(`Found ${reviews.length} reviews to process`);
        
        let updatedCount = 0;
        let skippedCount = 0;
        
        for (const review of reviews) {
            try {
                // Find the service provider record
                const serviceProvider = await serviceProvidersCollection.findOne({
                    _id: review.serviceProviderId
                });
                
                if (serviceProvider && serviceProvider.userId) {
                    // Update the review to use the user ID instead of service provider ID
                    await reviewsCollection.updateOne(
                        { _id: review._id },
                        { 
                            $set: { 
                                serviceProviderId: serviceProvider.userId,
                                migratedAt: new Date()
                            }
                        }
                    );
                    
                    console.log(`Updated review ${review._id} to use user ID ${serviceProvider.userId}`);
                    updatedCount++;
                } else {
                    console.log(`Skipped review ${review._id} - no matching service provider found`);
                    skippedCount++;
                }
            } catch (error) {
                console.error(`Error processing review ${review._id}:`, error.message);
            }
        }
        
        console.log(`\nMigration completed:`);
        console.log(`- Updated: ${updatedCount} reviews`);
        console.log(`- Skipped: ${skippedCount} reviews`);
        
    } catch (error) {
        console.error('Migration failed:', error);
    } finally {
        await client.close();
        console.log('Disconnected from MongoDB');
    }
}

// Run the migration
migrateReviewServiceProviderIds().catch(console.error);
