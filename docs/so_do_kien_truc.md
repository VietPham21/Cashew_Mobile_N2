# Sơ đồ Kiến trúc Tổng thể — Study Docs Cloud

Tài liệu này tổng hợp kiến trúc hệ thống và kiến trúc mã nguồn của ứng dụng **Study Docs Cloud** (dự án nhóm N2).

---

## 1. Sơ đồ Kiến trúc Hệ thống Trực quan

![Sơ đồ kiến trúc tổng thể Study Docs Cloud](./system_architecture_diagram.jpg)

*(Bạn cũng có thể mở trực tiếp file `so_do_kien_truc.html` trên trình duyệt để xem sơ đồ trực quan tương tác).*

---

## 2. Sơ đồ Cấu trúc Phân tầng (Architecture Diagram)

```mermaid
flowchart TB
    subgraph ClientTier["📱 1. CLIENT TIER (Flutter Multi-platform)"]
        direction TB
        subgraph Presentation["Presentation Layer (Giao diện & Trạng thái)"]
            UI["UI Pages / Screens\n(LoginPage, DocumentsListPage, DocumentDetailPage,\nDocumentFormPage, BorrowRequestsPage)"]
            VM["ViewModels (ChangeNotifier / Provider)\n(AuthViewModel, DocumentsViewModel, BorrowViewModel)"]
            UI <--> VM
        end

        subgraph Domain["Domain Layer (Nghiệp vụ cốt lõi)"]
            UC["Use Cases\n(SignInWithGoogle, SignOut)"]
            Entities["Domain Entities\n(StudyDocument, BorrowRequest, UserEntity)"]
            Contracts["Repository Contracts\n(DocumentsRepository, BorrowRepository, AuthRepository)"]
            VM --> UC
            UC --> Entities
            UC --> Contracts
        end

        subgraph Data["Data Layer (Xử lý dữ liệu)"]
            RepoImpl["Repository Implementations\n(DocumentsRepoImpl, BorrowRepoImpl, AuthRepoImpl)"]
            Mappers["Data Mappers & Parsers\n(fromMap, toMap, DocumentType)"]
            Contracts -.-> RepoImpl
            RepoImpl --> Mappers
        end
    end

    subgraph FirebaseCloud["🔥 2. FIREBASE CLOUD (Identity & Notifications)"]
        FAuth["Firebase Authentication\n(Google Sign-In, Session JWT Token)"]
        FCM["Firebase Cloud Messaging (FCM)\n(Push Notifications, Device Tokens)"]
    end

    subgraph SupabaseCloud["⚡ 3. SUPABASE CLOUD (Database & Storage)"]
        subgraph Database["PostgreSQL Database (RLS Protected)"]
            T_Users[("users\n(Profile, FCM Token)")]
            T_Docs[("documents\n(Metadata, Tags, GPS)")]
            T_Perms[("permissions\n(View / Edit Level)")]
            T_Borrow[("borrow_requests\n(Pending/Approved/Rejected)")]
            T_Notif[("notifications\n(In-app Realtime)")]
        end
        RLS{"Row Level Security (RLS)\ncurrent_app_user_id()"}
        SupaStorage[("Private Storage Bucket\n(documents - Signed URL 300s)")]
    end

    %% Liên kết
    RepoImpl -->|"OAuth & JWT"| FAuth
    RepoImpl -->|"Register Device Token"| FCM
    RepoImpl -->|"PostgREST API Requests"| RLS
    RLS --> Database
    RepoImpl -->|"Upload File / Xin Signed URL"| SupaStorage
```

---

## 3. Sơ đồ Luồng Nghiệp vụ Mượn & Chia sẻ File An toàn

```mermaid
sequenceDiagram
    autonumber
    actor UserB as Người mượn (User B)
    participant AppB as App Flutter (User B)
    participant DB as Supabase DB & RLS
    participant AppA as App Flutter (Owner A)
    actor UserA as Chủ tài liệu (User A)
    participant Storage as Supabase Storage (Private)

    UserB->>AppB: Xem tài liệu Public -> Bấm "Gửi yêu cầu mượn"
    AppB->>DB: INSERT into `borrow_requests` (status = 'pending')
    DB-->>AppA: Gửi thông báo đến Owner (FCM / Realtime)
    UserA->>AppA: Vào Borrow Requests -> Bấm "Chấp nhận"
    AppA->>DB: UPDATE status = 'approved' & INSERT into `permissions` (level: 'view')
    DB-->>AppB: Quyền xem file được kích hoạt
    AppB->>Storage: createFileSignedUrl(filePath, 300s)
    Storage-->>AppB: Trả về Signed URL tạm thời
    AppB-->>UserB: Mở xem trước và tải tệp đính kèm an toàn
```

---

## 4. Mô hình Chi tiết 3 Tầng Hệ thống

| Tầng (Tier) | Công nghệ chính | Trách nhiệm |
| :--- | :--- | :--- |
| **Client** | Flutter (Dart), Provider, Material 3 | Responsive UI (Android, Web, Desktop), quản lý trạng thái, validation, offline-friendly UI. |
| **Identity & Messaging** | Firebase Auth & FCM | Đăng nhập Google, cấp session token, gửi push notifications khi có yêu cầu mượn tài liệu. |
| **Data & Storage** | Supabase (PostgreSQL & Storage) | Lưu trữ metadata, xử lý phân quyền bằng SQL Row Level Security (RLS), lưu trữ file riêng tư qua Signed URL. |
