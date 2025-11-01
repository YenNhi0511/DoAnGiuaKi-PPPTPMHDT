// test-mongo.js - Script kiểm tra kết nối MongoDB
// Chạy: node test-mongo.js

import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

const MONGO_URI = process.env.MONGO_URI;

console.log('==========================================');
console.log('🔍 MONGODB CONNECTION TESTER');
console.log('==========================================\n');

// Hiển thị thông tin kết nối (ẩn password)
console.log('📋 THÔNG TIN KẾT NỐI:');
if (MONGO_URI) {
  const maskedURI = MONGO_URI.replace(/:[^:@]+@/, ':****@');
  console.log(`   URI: ${maskedURI}`);
  
  // Phân tích URI
  const uriMatch = MONGO_URI.match(/mongodb(\+srv)?:\/\/([^:]+):([^@]+)@([^/]+)\/([^?]+)/);
  if (uriMatch) {
    console.log(`   - Protocol: ${uriMatch[1] ? 'mongodb+srv' : 'mongodb'}`);
    console.log(`   - Username: ${uriMatch[2]}`);
    console.log(`   - Password: ${'*'.repeat(uriMatch[3].length)}`);
    console.log(`   - Host: ${uriMatch[4]}`);
    console.log(`   - Database: ${uriMatch[5]}`);
  }
} else {
  console.log('   ❌ Không tìm thấy MONGO_URI trong .env');
  process.exit(1);
}

console.log('\n🔗 BẮT ĐẦU KẾT NỐI...\n');

// Test kết nối
const testConnection = async () => {
  try {
    // Bước 1: Kết nối
    console.log('[1/4] Đang kết nối đến MongoDB...');
    const startTime = Date.now();
    
    await mongoose.connect(MONGO_URI, {
      serverSelectionTimeoutMS: 10000,
      socketTimeoutMS: 45000,
    });
    
    const connectionTime = Date.now() - startTime;
    console.log(`✅ Kết nối thành công! (${connectionTime}ms)\n`);

    // Bước 2: Kiểm tra database
    console.log('[2/4] Kiểm tra thông tin database...');
    const db = mongoose.connection;
    console.log(`   - Database name: ${db.name}`);
    console.log(`   - Host: ${db.host}`);
    console.log(`   - Port: ${db.port || 'N/A (Atlas)'}`);
    console.log(`   - ReadyState: ${db.readyState} (1=connected)`);

    // Bước 3: Kiểm tra collections
    console.log('\n[3/4] Kiểm tra collections...');
    const collections = await db.db.listCollections().toArray();
    if (collections.length === 0) {
      console.log('   ⚠️  Chưa có collection nào (database mới)');
      console.log('   💡 Collections sẽ được tạo khi bạn thêm dữ liệu đầu tiên');
    } else {
      console.log(`   ✅ Tìm thấy ${collections.length} collection(s):`);
      collections.forEach(col => {
        console.log(`      - ${col.name}`);
      });
    }

    // Bước 4: Test write/read
    console.log('\n[4/4] Test ghi/đọc dữ liệu...');
    
    // Tạo một collection test
    const TestModel = mongoose.model('Test', new mongoose.Schema({
      message: String,
      timestamp: { type: Date, default: Date.now }
    }));

    // Ghi dữ liệu
    const testDoc = await TestModel.create({
      message: 'MongoDB connection test successful!'
    });
    console.log('   ✅ Ghi dữ liệu thành công');

    // Đọc dữ liệu
    const readDoc = await TestModel.findById(testDoc._id);
    console.log('   ✅ Đọc dữ liệu thành công');

    // Xóa dữ liệu test
    await TestModel.deleteOne({ _id: testDoc._id });
    console.log('   ✅ Xóa dữ liệu test thành công');

    // Kết luận
    console.log('\n==========================================');
    console.log('🎉 HOÀN THÀNH - KẾT NỐI MONGODB HOÀN HẢO!');
    console.log('==========================================\n');
    console.log('✅ Bạn có thể sử dụng MongoDB Atlas');
    console.log('✅ Có thể chạy server: npm run dev\n');

  } catch (error) {
    console.log('\n==========================================');
    console.log('❌ LỖI KẾT NỐI MONGODB');
    console.log('==========================================\n');
    
    console.error('📛 Chi tiết lỗi:');
    console.error(`   - Message: ${error.message}`);
    console.error(`   - Code: ${error.code || 'N/A'}`);
    console.error(`   - Name: ${error.name}`);
    
    console.log('\n💡 GIẢI PHÁP:');
    
    // Phân tích lỗi cụ thể
    if (error.message.includes('ENOTFOUND') || error.message.includes('getaddrinfo')) {
      console.log('\n🔸 LỖI: Không tìm thấy host MongoDB Atlas');
      console.log('   NGUYÊN NHÂN:');
      console.log('   1. Không có kết nối internet');
      console.log('   2. Sai cluster URL trong connection string');
      console.log('   3. DNS không phân giải được');
      console.log('\n   CÁCH SỬA:');
      console.log('   1. Kiểm tra kết nối internet');
      console.log('   2. Ping test: ping cluster0.txz3p.mongodb.net');
      console.log('   3. Thử từ mạng khác (mobile hotspot)');
      console.log('   4. Kiểm tra lại cluster URL trên MongoDB Atlas');
      
    } else if (error.message.includes('Authentication failed') || error.message.includes('auth')) {
      console.log('\n🔸 LỖI: Xác thực thất bại');
      console.log('   NGUYÊN NHÂN:');
      console.log('   1. Sai username hoặc password');
      console.log('   2. Password chứa ký tự đặc biệt chưa encode');
      console.log('\n   CÁCH SỬA:');
      console.log('   1. Vào MongoDB Atlas > Database Access');
      console.log('   2. Kiểm tra username: yennhi0511');
      console.log('   3. Reset password hoặc tạo user mới');
      console.log('   4. Nếu password có @, /, : thì phải encode:');
      console.log('      @ -> %40, / -> %2F, : -> %3A');
      
    } else if (error.message.includes('IP') || error.message.includes('not authorized') || error.message.includes('whitelist')) {
      console.log('\n🔸 LỖI: IP chưa được whitelist');
      console.log('   NGUYÊN NHÂN:');
      console.log('   IP của bạn chưa được cho phép truy cập');
      console.log('\n   CÁCH SỬA:');
      console.log('   1. Vào MongoDB Atlas > Network Access');
      console.log('   2. Click "Add IP Address"');
      console.log('   3. Chọn "Allow Access from Anywhere" (0.0.0.0/0)');
      console.log('   4. Hoặc thêm IP hiện tại của bạn');
      console.log('   5. Đợi vài phút để áp dụng');
      
    } else if (error.message.includes('timeout') || error.message.includes('ETIMEDOUT')) {
      console.log('\n🔸 LỖI: Timeout kết nối');
      console.log('   NGUYÊN NHÂN:');
      console.log('   1. Mạng chậm hoặc không ổn định');
      console.log('   2. Firewall chặn kết nối');
      console.log('   3. VPN/Proxy gây cản trở');
      console.log('\n   CÁCH SỬA:');
      console.log('   1. Tắt VPN/Proxy');
      console.log('   2. Tắt Firewall/Antivirus tạm thời');
      console.log('   3. Thử từ mạng khác');
      console.log('   4. Sử dụng mongodb+srv:// (port 443)');
      
    } else {
      console.log('\n🔸 LỖI: Không xác định');
      console.log('   CÁCH SỬA:');
      console.log('   1. Kiểm tra lại connection string');
      console.log('   2. Xem log chi tiết phía trên');
      console.log('   3. Thử kết nối bằng MongoDB Compass');
    }
    
    console.log('\n📚 TÀI LIỆU THAM KHẢO:');
    console.log('   - MongoDB Atlas: https://cloud.mongodb.com');
    console.log('   - Troubleshooting: https://docs.mongodb.com/manual/reference/connection-string/');
    console.log('   - Community: https://www.mongodb.com/community/forums\n');
    
  } finally {
    // Đóng kết nối
    await mongoose.connection.close();
    process.exit(0);
  }
};

// Chạy test
testConnection();