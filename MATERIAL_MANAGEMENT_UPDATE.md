# Auto Workshop - Material Management Update

## New Features Added

### 1. **Portuguese Language Support (Português)**
- Added Portuguese (pt) as a third supported language
- Language toggle cycles through: English → Amharic (አማርኛ) → Portuguese → English
- All UI strings translated to Portuguese
- Updated main.dart to include Portuguese in supported locales

### 2. **Materials/Inventory Management Module**
- **New Screen**: `MaterialsScreen` - Complete materials inventory management
- **Features**:
  - View all registered materials with real-time quantity display
  - Search and filter materials by name or category
  - Add new materials with custom categories
  - Edit existing materials
  - Delete materials from inventory
  - Track materials by category

### 3. **Quantity Management with Increment/Decrement Buttons**
- **Controls for each material**:
  - **Decrease** button (-) - Decreases quantity by 1 (disabled when quantity is 0)
  - **Increase** button (+) - Increases quantity by 1
  - Visual quantity display showing current stock
  - Real-time updates to database

### 4. **Flexible Units Support**
Available units for materials:
- `piece` - Individual items (default)
- `mm` - Millimeters
- `cm` - Centimeters
- `m` - Meters
- `kg` - Kilograms
- `g` - Grams
- `l` - Liters
- `ml` - Milliliters
- `pensa` - Portuguese/Amharic word for caliper or custom measurement

Units can be easily extended by modifying the `_units` list in `add_material_screen.dart`.

### 5. **Material Registration and Management**
- **Register New Material**: Add materials with:
  - Material name (required)
  - Category for organization
  - Unit of measurement
  - Initial quantity
  - Optional description
- **Edit Material**: Update all material properties
- **Database Persistence**: All materials saved to SQLite database

### 6. **Updated Home Screen**
- New **Materials** module card added to home screen
- Yellow-themed card (color: #CA8A04) with inventory icon
- Direct navigation to materials management

## File Structure

### New Files Created:
```
lib/
├── models/
│   └── material.dart                    # Material model with quantity and units
├── db/
│   └── material_dao.dart               # Database access object for materials
└── screens/
    └── materials/
        ├── materials_screen.dart       # Main materials management screen
        └── add_material_screen.dart    # Add/Edit material screen

lib/l10n/
└── app_pt.dart                         # Portuguese language strings
```

### Updated Files:
```
lib/
├── main.dart                           # Added Portuguese locale
├── l10n/
│   ├── app_en.dart                    # Added material strings
│   ├── app_am.dart                    # Added material strings
│   └── locale_provider.dart           # Added Portuguese support & material getters
├── screens/
│   └── home_screen.dart              # Added Materials module, updated language toggle
└── db/
    └── database_helper.dart          # Added materials table creation
```

## Database Schema

### New Table: `materials`
```sql
CREATE TABLE materials (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT    NOT NULL UNIQUE,
  category    TEXT    NOT NULL DEFAULT '',
  unit        TEXT    NOT NULL DEFAULT 'piece',
  quantity    REAL    NOT NULL DEFAULT 0,
  description TEXT,
  created_at  TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP
)
```

## Usage

### Accessing Materials Module:
1. Launch the app
2. From the home screen, tap the **Materials** card (yellow icon)
3. View all registered materials

### Adding a New Material:
1. In Materials screen, tap the **+** button (FAB)
2. Fill in material details:
   - Name (required)
   - Category (optional, for grouping)
   - Unit (select from dropdown)
   - Stock quantity
   - Description (optional)
3. Tap **Save**

### Managing Quantity:
- **Increase**: Tap **+** button next to material to add 1 unit
- **Decrease**: Tap **-** button next to material to remove 1 unit (disabled at 0)
- **Direct Edit**: Tap the material to edit and manually set quantity

### Changing Language:
- On home screen, tap language toggle button (top right)
- Cycles: English → Amharic → Portuguese → English

## Notes for Icon Replacement

To replace the app icon with a material/equipment icon:

1. Replace `assets/icon/app_icon.png` with your new material icon
   - Recommended size: 192x192 or higher
   - Format: PNG with transparency recommended

2. Replace `assets/icon/app_icon_fg.png` with the foreground layer (for adaptive icons on Android)
   - Size: 108x108 (as per Android adaptive icon spec)

3. Run: `flutter clean && flutter pub get && flutter build apk`

## API Methods

### MaterialDao Methods:
- `getAll()` - Get all materials
- `getById(id)` - Get single material by ID
- `getByCategory(category)` - Get materials by category
- `insert(material)` - Add new material
- `update(material)` - Update material
- `updateQuantity(id, quantity)` - Set exact quantity
- `incrementQuantity(id, amount)` - Add to quantity
- `decrementQuantity(id, amount)` - Subtract from quantity
- `delete(id)` - Remove material
- `getGroupedByCategory()` - Get materials organized by category

## Future Enhancements

Potential improvements for future releases:
- [ ] Material history/logs
- [ ] Low stock alerts
- [ ] Barcode scanning for materials
- [ ] Material usage tracking
- [ ] Export materials to CSV
- [ ] Integration with tool borrowing system
- [ ] Material cost tracking
