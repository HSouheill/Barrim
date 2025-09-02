const { MongoClient } = require('mongodb');

async function migrateCertificates() {
    const uri = 'mongodb://localhost:27017';
    const client = new MongoClient(uri);

    try {
        await client.connect();
        console.log('Connected to MongoDB');

        const db = client.db('barrim');
        const usersCollection = db.collection('users');

        // Find all service providers with the old certificateImage field
        const serviceProviders = await usersCollection.find({
            userType: 'serviceProvider',
            'serviceProviderInfo.certificateImage': { $exists: true, $ne: null, $ne: '' }
        }).toArray();

        console.log(`Found ${serviceProviders.length} service providers with old certificate format`);

        for (const user of serviceProviders) {
            const oldCertificatePath = user.serviceProviderInfo.certificateImage;
            
            if (oldCertificatePath && oldCertificatePath !== '') {
                // Create the new certificateImages array with the old certificate
                const updateResult = await usersCollection.updateOne(
                    { _id: user._id },
                    {
                        $set: {
                            'serviceProviderInfo.certificateImages': [oldCertificatePath],
                            updatedAt: new Date()
                        },
                        $unset: {
                            'serviceProviderInfo.certificateImage': ''
                        }
                    }
                );

                if (updateResult.modifiedCount > 0) {
                    console.log(`Migrated certificate for user ${user._id}: ${oldCertificatePath}`);
                } else {
                    console.log(`Failed to migrate certificate for user ${user._id}`);
                }
            }
        }

        console.log('Certificate migration completed successfully');

    } catch (error) {
        console.error('Migration failed:', error);
    } finally {
        await client.close();
        console.log('Disconnected from MongoDB');
    }
}

// Run the migration
migrateCertificates().catch(console.error);
