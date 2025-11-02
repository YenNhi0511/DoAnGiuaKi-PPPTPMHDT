// api/src/routes/classes.js
import express from 'express';
import Class from '../models/Class.js';
import authMiddleware from '../middlewares/auth.js';

const router = express.Router();

// Middleware kiểm tra admin
const adminMiddleware = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Chỉ admin mới có quyền này' });
  }
  next();
};

// GET /api/classes - Lấy tất cả lớp (public cho student chọn)
router.get('/', authMiddleware, async (req, res) => {
  try {
    const classes = await Class.find({ isActive: true }).sort({ name: 1 });
    res.json(classes);
  } catch (error) {
    console.error('Lỗi lấy danh sách lớp:', error);
    res.status(500).json({ message: 'Lỗi máy chủ' });
  }
});

// POST /api/classes - Tạo lớp mới (Admin only)
router.post('/', [authMiddleware, adminMiddleware], async (req, res) => {
  try {
    const { name, description } = req.body;

    if (!name || name.trim() === '') {
      return res.status(400).json({ message: 'Vui lòng nhập tên lớp' });
    }

    // Kiểm tra trùng
    const existing = await Class.findOne({ name: name.trim() });
    if (existing) {
      return res.status(409).json({ message: 'Lớp này đã tồn tại' });
    }

    const newClass = new Class({
      name: name.trim(),
      description: description || '',
    });

    await newClass.save();
    res.status(201).json(newClass);
  } catch (error) {
    console.error('Lỗi tạo lớp:', error);
    res.status(500).json({ message: 'Lỗi máy chủ' });
  }
});

// PUT /api/classes/:id - Cập nhật lớp (Admin only)
router.put('/:id', [authMiddleware, adminMiddleware], async (req, res) => {
  try {
    const { name, description, isActive } = req.body;

    const classData = await Class.findById(req.params.id);
    if (!classData) {
      return res.status(404).json({ message: 'Không tìm thấy lớp' });
    }

    // Kiểm tra trùng tên (nếu đổi tên)
    if (name && name !== classData.name) {
      const existing = await Class.findOne({ name: name.trim() });
      if (existing) {
        return res.status(409).json({ message: 'Tên lớp này đã tồn tại' });
      }
      classData.name = name.trim();
    }

    if (description !== undefined) classData.description = description;
    if (isActive !== undefined) classData.isActive = isActive;

    await classData.save();
    res.json(classData);
  } catch (error) {
    console.error('Lỗi cập nhật lớp:', error);
    res.status(500).json({ message: 'Lỗi máy chủ' });
  }
});

// DELETE /api/classes/:id - Xóa lớp (Admin only)
router.delete('/:id', [authMiddleware, adminMiddleware], async (req, res) => {
  try {
    const classData = await Class.findByIdAndDelete(req.params.id);
    if (!classData) {
      return res.status(404).json({ message: 'Không tìm thấy lớp' });
    }
    res.json({ message: 'Xóa lớp thành công' });
  } catch (error) {
    console.error('Lỗi xóa lớp:', error);
    res.status(500).json({ message: 'Lỗi máy chủ' });
  }
});

export default router;