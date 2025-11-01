// src/index.js
import express from 'express';
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import cors from 'cors';
import os from 'os';

import authRoutes from './routes/auth.js';
import activityRoutes from './routes/activities.js';
import adminRoutes from './routes/admin.js';

dotenv.config();

const app = express();

// ================== TỰ ĐỘNG NHẬN DIỆN MÔI TRƯỜNG ==================
function detectEnvironment() {
  const networkInterfaces = os.networkInterfaces();
  let localIP = 'localhost';
  
  // Tìm IP local (không phải loopback)
  for (const interfaceName in networkInterfaces) {
    const interfaces = networkInterfaces[interfaceName];
    if (!interfaces) continue;
    
    for (const net of interfaces) {
      // Bỏ qua IPv6 và loopback
      if (net.family === 'IPv4' && !net.internal) {
        localIP = net.address;
        break;
      }
    }
    if (localIP !== 'localhost') break;
  }
  
  return {
    localIP,
    hostname: os.hostname(),
    platform: os.platform(),
  };
}

const env = detectEnvironment();
console.log('\n🔍 THÔNG TIN MÔI TRƯỜNG:');
console.log(`   - IP Local: ${env.localIP}`);
console.log(`   - Hostname: ${env.hostname}`);
console.log(`   - Platform: ${env.platform}`);

// ================== CORS - HỖ TRỢ CẢ EMULATOR VÀ MÁY THẬT ==================
const allowedOrigins = [
  '*',
  'http://localhost:5173',
  `http://${env.localIP}:5173`,
  'http://10.0.2.2:4000',     // Android Emulator
  `http://${env.localIP}:4000`, // Máy thật trong LAN
];

app.use(cors({
  origin: function(origin, callback) {
    // Cho phép request không có origin (như mobile apps)
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.indexOf(origin) !== -1 || allowedOrigins.includes('*')) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  credentials: true,
}));

app.use(express.json());

// ================== KẾT NỐI MONGODB với KIỂM TRA CHI TIẾT ==================
const PORT = process.env.PORT || 4000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/khoa_cntt_app';

console.log('\n📦 ĐANG KẾT NỐI MONGODB...');
console.log(`   URI: ${MONGO_URI.replace(/:[^:@]+@/, ':****@')}`); // Ẩn password

// Cấu hình kết nối MongoDB
const mongoOptions = {
  serverSelectionTimeoutMS: 5000, // Timeout sau 5s
  socketTimeoutMS: 45000,
};

mongoose
  .connect(MONGO_URI, mongoOptions)
  .then(() => {
    console.log('✅ MongoDB đã kết nối thành công!');
    console.log(`   - Database: ${mongoose.connection.name}`);
    console.log(`   - Host: ${mongoose.connection.host}`);
    console.log(`   - Port: ${mongoose.connection.port || 'N/A (Atlas)'}`);
  })
  .catch((err) => {
    console.error('❌ LỖI KẾT NỐI MONGODB:');
    console.error(`   - Message: ${err.message}`);
    console.error(`   - Code: ${err.code || 'N/A'}`);
    
    // Kiểm tra các lỗi phổ biến
    if (err.message.includes('ENOTFOUND')) {
      console.error('\n💡 GIẢI PHÁP: Kiểm tra kết nối internet hoặc địa chỉ MongoDB Atlas');
    } else if (err.message.includes('authentication failed')) {
      console.error('\n💡 GIẢI PHÁP: Sai username/password MongoDB Atlas');
    } else if (err.message.includes('IP') || err.message.includes('whitelist')) {
      console.error('\n💡 GIẢI PHÁP: IP của bạn chưa được whitelist trên MongoDB Atlas');
      console.error(`   Thêm IP: ${env.localIP} hoặc 0.0.0.0/0 (cho phép tất cả)`);
    } else if (err.code === 'ECONNREFUSED') {
      console.error('\n💡 GIẢI PHÁP: MongoDB local không chạy hoặc sai port');
    }
    
    console.error('\n⚠️  Server vẫn chạy nhưng không có database!');
  });

// Xử lý các sự kiện MongoDB
mongoose.connection.on('disconnected', () => {
  console.warn('⚠️  MongoDB bị ngắt kết nối');
});

mongoose.connection.on('reconnected', () => {
  console.log('🔄 MongoDB đã kết nối lại');
});

mongoose.connection.on('error', (err) => {
  console.error('❌ Lỗi MongoDB runtime:', err.message);
});

// ================== ROUTES ==================
app.use('/api/auth', authRoutes);
app.use('/api/activities', activityRoutes);
app.use('/api/admin', adminRoutes);

// Route test kết nối
app.get('/api/health', (req, res) => {
  const mongoStatus = mongoose.connection.readyState;
  const statusMap = {
    0: 'disconnected',
    1: 'connected',
    2: 'connecting',
    3: 'disconnecting',
  };
  
  res.json({
    status: 'Server is running',
    mongodb: statusMap[mongoStatus] || 'unknown',
    environment: {
      localIP: env.localIP,
      hostname: env.hostname,
    },
    endpoints: {
      emulator: `http://10.0.2.2:${PORT}`,
      local: `http://${env.localIP}:${PORT}`,
      localhost: `http://localhost:${PORT}`,
    },
  });
});

// ================== START SERVER ==================
app.listen(PORT, '0.0.0.0', () => {
  console.log('\n🚀 SERVER ĐANG CHẠY:');
  console.log(`   - Emulator (Android): http://10.0.2.2:${PORT}`);
  console.log(`   - Máy thật (LAN):     http://${env.localIP}:${PORT}`);
  console.log(`   - Localhost:          http://localhost:${PORT}`);
  console.log(`\n📱 CẤU HÌNH APP (Flutter config.dart):`);
  console.log(`   - Emulator: 'http://10.0.2.2:${PORT}/api'`);
  console.log(`   - Máy thật: 'http://${env.localIP}:${PORT}/api'`);
  console.log('\n✅ Kiểm tra health: http://localhost:' + PORT + '/api/health\n');
});