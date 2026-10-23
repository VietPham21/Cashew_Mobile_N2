# Study Docs Cloud

Ứng dụng quản lý tài liệu học tập, đồng bộ qua Firebase, đăng nhập Google..

Bài tập nhóm môn Phát triển ứng dụng di động - nhóm N2.

## Yêu cầu

- Flutter SDK (xem phiên bản bằng `flutter --version`, ghi đúng phiên bản nhóm đang dùng)
- Google Chrome

```bash
flutter doctor
```

## Cách chạy (Web)

Google Sign-In được cấu hình cho `http://localhost:5000`, nên **bắt buộc chạy đúng port 5000**.

```bash
git clone https://github.com/VietPham21/Cashew_Mobile_N2.git
cd Cashew_Mobile_N2/study_docs_cloud
flutter pub get
flutter run -d chrome --web-port=5000
```

## Lỗi thường gặp

- **Đăng nhập Google lỗi:** kiểm tra đã chạy đúng `--web-port=5000` chưa.
- **Lỗi package/cache:**
```bash
  flutter clean
  flutter pub get
```
- **`No pubspec.yaml file found`:** đang đứng sai thư mục, phải `cd` vào `study_docs_cloud`.

## Cấu trúc repo

| Thư mục | Nội dung |
|---|---|
| `study_docs_cloud/` | Project Flutter của nhóm |
| `budget/` | Mã nguồn Cashew gốc (tham khảo) |

## Ghi nguồn

Repo này dựa trên / tham khảo [Cashew](https://github.com/jameskokoska/Cashew) của James Kokoska, phát hành theo giấy phép ghi trong file `LICENSE`.
