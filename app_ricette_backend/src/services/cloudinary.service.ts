import { v2 as cloudinary } from 'cloudinary';
import { Readable } from 'stream';

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

export const uploadImageToCloudinary = async (
  fileBuffer: Buffer, 
  folder: string = 'orsocook',
  mimetype?: string,
  filename?: string
): Promise<string> => {
  return new Promise((resolve, reject) => {
    console.log('☁️ [Cloudinary] Starting upload...');
    console.log(`   📏 Buffer size: ${(fileBuffer.length / 1024).toFixed(2)} KB`);
    console.log(`   📄 MIME type: ${mimetype || 'not specified'}`);
    console.log(`   📝 Filename: ${filename || 'not specified'}`);
    
    // Simple PNG check
    if (mimetype === 'image/png' || filename?.toLowerCase().endsWith('.png')) {
      console.log('   🎯 PNG DETECTED - Special handling');
      if (fileBuffer.length > 5 * 1024 * 1024) {
        console.warn('   ⚠️ PNG > 5MB: May cause timeout on Vercel');
      }
    }

    // Create upload stream
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: 'auto',
      },
      (error, result) => {
        if (error) {
          console.error('❌ [Cloudinary] Upload error:', error.message);
          reject(error);
        } else if (result) {
          console.log('✅ [Cloudinary] Upload successful!');
          console.log(`   🔗 URL: ${result.secure_url}`);
          console.log(`   🖼️ Format: ${result.format}`);
          resolve(result.secure_url);
        } else {
          console.error('❌ [Cloudinary] No result returned');
          reject(new Error('No result from Cloudinary'));
        }
      }
    );

    // Convert buffer to stream
    const readableStream = new Readable();
    readableStream.push(fileBuffer);
    readableStream.push(null);
    
    // Pipe the streams
    readableStream.pipe(uploadStream);
    
    console.log('📤 [Cloudinary] Buffer sent to Cloudinary...');
  });
};

// Delete image (optional)
export const deleteImageFromCloudinary = async (publicId: string): Promise<void> => {
  try {
    console.log(`🗑️ [Cloudinary] Deleting image: ${publicId}`);
    const result = await cloudinary.uploader.destroy(publicId);
    console.log('✅ Image deleted from Cloudinary');
  } catch (error) {
    console.error('❌ Error deleting image from Cloudinary:', error);
    throw error;
  }
};