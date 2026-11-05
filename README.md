# StockNest – Stock Inventory Manager

A Flutter-based stock inventory management application built using Firebase Cloud Firestore.

StockNest helps users manage inventory, monitor stock levels, search products, and identify items that need reordering through a clean and responsive interface.

## Features

- **Dashboard:** View inventory statistics and stock summaries.
- **Add Items:** Register inventory items with validated input fields.
- **Inventory Records:** Retrieve and display stored stock items.
- **Search:** Search items by SKU or item name.
- **Category Filter:** Filter inventory by category.
- **Low Stock Alerts:** Identify items where quantity is at or below the reorder level.
- **Sorting:** Sort inventory by quantity in ascending or descending order.
- **Cloud Database:** Store and retrieve inventory records using Firebase Cloud Firestore.

## Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Frontend and application development |
| Dart | Programming language |
| Firebase Core | Firebase integration |
| Cloud Firestore | Cloud database |
| Material Design | User interface |

## Project Structure

```text
lib/
├── main.dart
├── firebase_options.dart
├── models/
│   └── stock_item.dart
├── screens/
│   └── stock_inventory_screen.dart
├── services/
│   └── stock_service.dart
└── utils/
    └── stock_filter.dart
```

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Visual Studio Code or Android Studio
- Firebase project

### Installation

1. Clone the repository:

```bash
git clone https://github.com/YadurajSiddarth/Stock-Inventory-Manager.git
```

2. Navigate into the project:

```bash
cd Stock-Inventory-Manager
```

3. Install dependencies:

```bash
flutter pub get
```

4. Run the application:

```bash
flutter run
```

## Firebase Configuration

This project uses Firebase Cloud Firestore for inventory storage.

The Firebase project must be configured before running the application. If setting up a new Firebase project, configure FlutterFire and enable Cloud Firestore.

## Academic Information

**Course:** NET4207  
**Project:** Stock Inventory Manager  
**Application Name:** StockNest

---

Developed as part of the NET4207 project.
