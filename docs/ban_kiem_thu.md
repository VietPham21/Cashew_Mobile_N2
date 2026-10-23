# Bản Kế Hoạch & Bộ Kịch Bản Kiểm Thử (Test Plan & Test Cases)
### Dự án: Study Docs Cloud — Nhóm N2

---

## 1. Tổng Quan & Mục Tiêu Kiểm Thử

Tài liệu này xác định phạm vi, môi trường, chiến lược và danh sách các ca kiểm thử (Test Cases) chi tiết cho ứng dụng **Study Docs Cloud**, đảm bảo tính toàn vẹn dữ liệu, hiệu năng, trải nghiệm người dùng và tính bảo mật theo mô hình **Row Level Security (RLS)**.

### Mục tiêu chính:
1. **Kiểm thử đơn vị (Unit Testing):** Xác thực logic nghiệp vụ tại tầng Domain (Use Cases, Validation) và tầng Data (Mappers, DTOs).
2. **Kiểm thử tích hợp (Integration Testing):** Kiểm tra tương tác giữa Flutter Client, Firebase Auth và Supabase BaaS (PostgreSQL + Private Storage).
3. **Kiểm thử bảo mật (Security & Access Control):** Xác thực chính sách RLS, đảm bảo tài liệu riêng tư và tệp đính kèm không bị rò rỉ nếu chưa được cấp quyền.
4. **Kiểm thử giao diện & luồng người dùng (UI / E2E Testing):** Đảm bảo giao diện phản hồi mượt mà trên nhiều kích thước màn hình (Mobile, Web localhost:5000, Desktop).

---

## 2. Môi Trường & Công Cụ Kiểm Thử

| Thành phần | Công cụ / Môi trường | Ghi chú |
| :--- | :--- | :--- |
| **Framework kiểm thử** | `flutter_test`, `mockito` | Chạy tự động các Unit Test / Widget Test |
| **Nền tảng kiểm thử** | Chrome (`--web-port=5000`), Android Emulator | Cần port 5000 để khớp cấu hình Google OAuth |
| **Dịch vụ Backend** | Firebase Auth Emulator / Supabase Local / Staging | Kiểm thử luồng xác thực và phân quyền RLS |
| **Mocking** | `build_runner`, `mockito/annotations.dart` | Sinh mock repository cho UseCase testing |

---

## 3. Ma Trận Kịch Bản Kiểm Thử Chi Tiết (Test Cases Matrix)

### 3.1. Phân hệ Xác thực (Authentication — `auth`)

| Mã Test Case | Tên kịch bản | Điều kiện tiên quyết | Các bước thực hiện | Kết quả mong đợi | Mức độ |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-AUTH-01** | Đăng nhập Google thành công | Thiết bị có kết nối mạng, tài khoản Google hợp lệ | 1. Nhấn nút "Đăng nhập bằng Google"<br>2. Chọn tài khoản Google | Đăng nhập thành công, nhận JWT Token, tự động đồng bộ profile vào bảng `users`, điều hướng vào `DocumentsListPage`. | Critical |
| **TC-AUTH-02** | Hủy đăng nhập Google | Màn hình Login | 1. Bấm đăng nhập<br>2. Đóng popup tài khoản Google | Ứng dụng không bị crash, hiển thị thông báo hủy hoặc giữ nguyên trạng thái màn hình Login. | High |
| **TC-AUTH-03** | Đăng xuất (Sign Out) | Đang ở trạng thái đăng nhập | 1. Bấm nút đăng xuất ở thanh AppBar<br>2. Xác nhận | Phiên làm việc bị hủy, token Firebase bị xóa, xóa trạng thái ViewModel, điều hướng trở lại màn hình `LoginPage`. | High |
| **TC-AUTH-04** | Đăng ký FCM Device Token | Đăng nhập thành công | 1. Đăng nhập vào app<br>2. Kiểm tra token gửi lên Supabase | FCM Token được ghi nhận chính xác vào cột `fcm_token` của user tương ứng trong bảng `users`. | Medium |

---

### 3.2. Phân hệ Quản lý Tài liệu (Documents Management — `documents`)

| Mã Test Case | Tên kịch bản | Điều kiện tiên quyết | Các bước thực hiện | Kết quả mong đợi | Mức độ |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-DOC-01** | Thêm mới tài liệu hợp lệ | Đã đăng nhập | 1. Mở `DocumentFormPage`<br>2. Nhập Tiêu đề, Môn học, chọn Loại (lecture)<br>3. Thêm Tags và Ghi chú<br>4. Nhấn "Lưu" | Tài liệu được tạo mới thành công, hiển thị ngay trên đầu danh sách (sắp xếp theo `updated_at DESC`). | Critical |
| **TC-DOC-02** | Validate: Bỏ trống Tiêu đề | Đang ở form thêm tài liệu | 1. Để trống trường Tiêu đề (Title)<br>2. Nhập các trường khác<br>3. Bấm "Lưu" | Form chặn submit, ném lỗi `ValidationFailure`, hiển thị cảnh báo đỏ yêu cầu nhập tiêu đề. | High |
| **TC-DOC-03** | Validate: Bỏ trống Môn học | Đang ở form thêm tài liệu | 1. Nhập Tiêu đề, để trống Môn học (Course)<br>2. Bấm "Lưu" | Form chặn submit, ném lỗi `ValidationFailure`, không gọi repository. | High |
| **TC-DOC-04** | Đính kèm tệp tin khi tạo tài liệu | Form thêm tài liệu | 1. Bấm chọn tệp (PDF/ảnh/Word)<br>2. Nhập thông tin và bấm Lưu | Tệp được upload nhị phân lên bucket `documents`, lưu đường dẫn `file_path`, tên `file_name` và kích thước `file_size` vào DB. | High |
| **TC-DOC-05** | Chỉnh sửa tài liệu | Có tài liệu do chính mình tạo | 1. Vào chi tiết tài liệu<br>2. Bấm nút Sửa<br>3. Đổi tiêu đề / tags và Lưu | Dữ liệu được cập nhật, trường `updated_at` được làm mới, danh sách hiển thị thông tin mới. | High |
| **TC-DOC-06** | Xóa tài liệu & dọn dẹp Storage | Có tài liệu có file đính kèm | 1. Chọn Xóa tài liệu<br>2. Xác nhận trong Dialog cảnh báo | Bản ghi trong bảng `documents` bị xóa, tệp tin vật lý trong Storage bucket cũng bị xóa dọn dẹp. | High |
| **TC-DOC-07** | Đính kèm vị trí địa lý (GPS) | Mở form tạo/sửa tài liệu | 1. Bấm chọn vị trí<br>2. Chọn tọa độ trên bản đồ `LocationPickerPage`<br>3. Nhập tên địa điểm và Lưu | Lưu thành công tọa độ (`latitude`, `longitude`) và `location_name`. Trang chi tiết hiển thị thẻ vị trí. | Medium |
| **TC-DOC-08** | Tìm kiếm từ khóa & Lọc theo môn học | Có danh sách nhiều tài liệu | 1. Nhập từ khóa vào thanh tìm kiếm<br>2. Chọn filter chip loại tài liệu | Danh sách lọc tức thời theo `ilike` trên title, course, notes và đúng type đã chọn. | Medium |
| **TC-DOC-09** | Thuật toán gợi ý ("For You") | Có tài liệu cá nhân đã gắn tags | 1. Mở trang `RecommendationsPage` | Hiển thị tối đa 10 tài liệu công khai của người khác có số lượng tags trùng nhiều nhất với tags của người dùng. | Medium |

---

### 3.3. Phân hệ Mượn & Phân quyền (Borrow & Permissions)

| Mã Test Case | Tên kịch bản | Điều kiện tiên quyết | Các bước thực hiện | Kết quả mong đợi | Mức độ |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-BRW-01** | Gửi yêu cầu mượn tài liệu public | User B xem tài liệu của User A | 1. User B mở chi tiết tài liệu<br>2. Nhấn "Yêu cầu mượn (Request to Borrow)"<br>3. Nhập lời nhắn và gửi | Bản ghi mới trong `borrow_requests` với `status: 'pending'`, email người mượn được lưu chính xác. | Critical |
| **TC-BRW-02** | Owner duyệt yêu cầu mượn | User A đăng nhập, có yêu cầu pending | 1. User A mở `BorrowRequestsPage`<br>2. Bấm "Chấp nhận" (Approve) | `borrow_requests.status` đổi thành `approved`, tự động tạo bản ghi trong `permissions` với quyền `view` cho User B. | Critical |
| **TC-BRW-03** | Owner từ chối yêu cầu mượn | User A đăng nhập, có yêu cầu pending | 1. User A mở `BorrowRequestsPage`<br>2. Bấm "Từ chối" (Reject) | `status` chuyển thành `rejected`, không tạo bản ghi trong `permissions`. | High |
| **TC-BRW-04** | Chia sẻ trực tiếp qua Email | User A sở hữu tài liệu | 1. Bấm nút Share trong chi tiết tài liệu<br>2. Nhập email User B và chọn quyền `edit` | Bản ghi permissions được tạo, User B có thể xem và chỉnh sửa tài liệu. | High |

---

### 3.4. Phân hệ Bảo mật Dữ liệu & Storage (Security & RLS)

| Mã Test Case | Tên kịch bản | Điều kiện tiên quyết | Các bước thực hiện | Kết quả mong đợi | Mức độ |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-SEC-01** | Bảo vệ tài liệu Private qua RLS | Tài liệu của User A đặt `is_public = false` | User B (chưa được chia sẻ) thực hiện query SELECT lấy tài liệu này | Supabase RLS trả về rỗng (0 rows), User B không thể đọc được metadata. | Critical |
| **TC-SEC-02** | Ngăn chặn sửa tài liệu của người khác | Tài liệu thuộc sở hữu của User A | User B gửi request UPDATE trực tiếp | Lệnh UPDATE bị chặn bởi RLS Policy `documents_update`, báo lỗi quyền hạn. | Critical |
| **TC-SEC-03** | Truy cập file riêng tư qua Signed URL | User B đã được duyệt quyền `view` | User B bấm mở file | Client gọi `createFileSignedUrl(path, 300)` thành công, sinh đường dẫn tạm có chữ ký (hết hạn sau 300 giây). | Critical |
| **TC-SEC-04** | Ngăn chặn tải file trực tiếp (Public URL) | Tệp nằm trong bucket `documents` | Thử truy cập file bằng đường dẫn public trực tiếp | Supabase Storage trả về HTTP 403 Forbidden hoặc 404 (do bucket là private). | Critical |

---

## 4. Kịch Bản Code Unit Test Mẫu (Đã tích hợp trong dự án)

Ví dụ về ca kiểm thử Use Case `AddDocument` sử dụng `mockito` tại [`test/features/documents/domain/add_document_test.dart`](file:///f:/FlutterProjects/Cashew_Mobile_N2/study_docs_cloud/test/features/documents/domain/add_document_test.dart):

```dart
group('AddDocument UseCase Unit Tests', () {
  test('gọi repository.add khi dữ liệu hợp lệ', () async {
    when(mockRepo.add(validDoc)).thenAnswer((_) async {});
    await useCase(validDoc);
    verify(mockRepo.add(validDoc)).called(1);
  });

  test('throw ValidationFailure khi title rỗng', () {
    final badDoc = validDoc.copyWith(title: '');
    expect(() => useCase(badDoc), throwsA(isA<ValidationFailure>()));
    verifyNever(mockRepo.add(any));
  });

  test('throw ValidationFailure khi course rỗng', () {
    final badDoc = validDoc.copyWith(course: '');
    expect(() => useCase(badDoc), throwsA(isA<ValidationFailure>()));
    verifyNever(mockRepo.add(any));
  });
});
```

---

## 5. Tiêu Chuẩn Đánh Giá Chấp Nhận (Pass / Fail Criteria)

* **100% Pass** cho các ca kiểm thử mức độ **Critical** (Xác thực Google, phân quyền RLS, chống rò rỉ file private, CRUD tài liệu).
* Tỷ lệ lỗi mức **High** không vượt quá 0 lỗi tồn đọng trước khi phát hành.
* Các lỗi mức **Medium / Low** (như độ trễ giao diện, định dạng thời gian) có thể ghi nhận vào backlog cải tiến phiên bản tiếp theo.
