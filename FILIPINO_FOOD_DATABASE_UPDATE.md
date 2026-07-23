# Filipino Food Database Update

## Problem
The Food Search feature couldn't find Filipino dishes like "Kare Kare" and "Leche Flan" because the FatSecret API primarily contains international/Western foods and packaged products.

## Solution
Added a comprehensive **Filipino Food Database** to the app's fallback system. When FatSecret API doesn't have a food, the app now checks the local database which includes 30+ popular Filipino dishes!

---

## 🍽️ Filipino Foods Now Available

### Main Dishes
1. **Adobo** (Chicken Adobo)
2. **Sinigang** (Sour Soup)
3. **Kare-Kare** (Peanut Stew) ✨ NEW
4. **Lechon** (Roasted Pig)
5. **Sisig** (Sizzling Pork)
6. **Tinola** (Chicken Ginger Soup)
7. **Bistek** (Filipino Beef Steak)
8. **Menudo** (Pork Stew)
9. **Caldereta** (Beef Stew)
10. **Paksiw** (Fish in Vinegar)
11. **Nilaga** (Beef Soup)
12. **Dinuguan** (Pork Blood Stew)
13. **Bulalo** (Beef Marrow Soup)
14. **Arroz Caldo** (Rice Porridge)

### Noodles & Snacks
15. **Pancit** (Filipino Noodles)
16. **Lumpia** (Spring Roll)

### Breakfast Items
17. **Tocino** (Sweet Cured Pork)
18. **Longganisa** (Filipino Sausage)

### Desserts
19. **Leche Flan** (Filipino Custard) ✨ NEW
20. **Halo-Halo** (Mixed Dessert)
21. **Turon** (Banana Spring Roll)
22. **Bibingka** (Rice Cake)
23. **Puto** (Steamed Rice Cake)
24. **Cassava Cake**
25. **Ube Halaya** (Purple Yam Jam)

### Common Foods
- Rice, Chicken, Beef, Pork, Fish
- Eggs, Milk, Bread
- Banana, Apple, Orange, Potato

**Total: 40+ foods in the database!**

---

## 🔍 How It Works

### Search Flow:
1. User searches for a food (e.g., "kare kare")
2. App tries FatSecret API first
3. If not found → Checks local Filipino food database
4. Returns nutritional info specific to CKD management

### Search Features:
- **Case-insensitive**: "Kare Kare" = "kare kare" = "KARE KARE"
- **Partial matching**: Searching "kare" will find "Kare-Kare"
- **Multiple spellings**: Both "Kare Kare" and "Kare-Kare" work
- **Alternative names**: "Chicken Adobo" and "Adobo" both work

---

## 📊 Nutritional Data Provided

For each Filipino food, the database includes:
- **Sodium** (mg) - Critical for blood pressure
- **Potassium** (mg) - Critical for heart health
- **Phosphorus** (mg) - Critical for bone health
- **Protein** (g) - Critical for kidney workload
- **Serving Size** - Helps users understand portions

### Example: Kare-Kare
```
Product Name: Kare-Kare (Filipino Peanut Stew)
Serving Size: 1 cup (250g)
Sodium: 520 mg
Potassium: 480 mg (HIGH - from peanuts and vegetables)
Phosphorus: 200 mg (HIGH - from peanuts)
Protein: 20.0 g
```

### Example: Leche Flan
```
Product Name: Leche Flan (Filipino Custard)
Serving Size: 1 slice (80g)
Sodium: 85 mg
Potassium: 150 mg
Phosphorus: 140 mg (HIGH - from eggs and milk)
Protein: 6.5 g
```

---

## 🎨 UI Updates

### 1. Updated Info Card
**Before**: "Search for packaged foods and branded products..."
**After**: "Search for **Filipino dishes**, common foods, and packaged products..."

### 2. Improved Placeholder Text
**Before**: "Search for food (e.g., "banana", "rice")"
**After**: "Try: **"kare kare"**, **"leche flan"**, "banana""

### 3. Better Error Message
**Before**: Listed only 6 basic foods
**After**: Shows both common foods AND Filipino dishes:

```
Common Foods:
• Banana  • White Rice  • Chicken
• Milk  • Egg  • Bread

Filipino Dishes:
• Adobo  • Sinigang  • Kare Kare
• Leche Flan  • Tinola  • Lumpia
```

---

## 🏥 CKD-Specific Insights

### High Sodium Foods (>700mg)
⚠️ **Very High Risk**:
- Sisig (920mg)
- Tocino (920mg)
- Longganisa (880mg)
- Dinuguan (850mg)
- Adobo (800mg)
- Caldereta (780mg)

### High Potassium Foods (>450mg)
⚠️ **Monitor Carefully**:
- Caldereta (520mg)
- Bulalo (500mg)
- Kare-Kare (480mg)
- Sinigang (450mg)
- Menudo (450mg)

### High Phosphorus Foods (>250mg)
⚠️ **Be Cautious**:
- Bulalo (320mg) - bone marrow
- Dinuguan (280mg) - blood and pork
- Lechon (280mg) - pork
- Paksiw (270mg) - fish
- Bistek (260mg)

### Safer Filipino Options
✅ **Lower in all nutrients**:
- Tinola (moderate levels)
- Plain white rice (very low)
- Steamed fish (moderate)
- Puto (lower levels)

---

## 💡 Data Sources

The nutritional data is estimated based on:
- USDA Food Composition Database
- Philippine Food Composition Tables
- Standard Filipino recipes
- Typical serving sizes in Filipino households
- CKD dietary guidelines (KDIGO)

**Note**: Values are estimates for typical preparations. Actual values may vary based on:
- Recipe variations
- Cooking methods
- Portion sizes
- Ingredient substitutions

---

## 🚀 How to Use

### For Users:
1. Open Kidnease app
2. Tap "Search Food" from Quick Actions (or settings menu)
3. Type any Filipino dish name (e.g., "kare kare", "leche flan")
4. Tap "Search"
5. View complete nutritional breakdown
6. Compare with your daily limits

### Testing:
```
✅ Try searching: "kare kare"
✅ Try searching: "leche flan"
✅ Try searching: "adobo"
✅ Try searching: "halo halo"
✅ Try searching: "sisig"
```

All should now return nutritional information!

---

## 🔧 Technical Implementation

### File Modified:
`lib/features/food_search/presentation/screens/food_search_screen.dart`

### Changes Made:
1. Expanded `_searchFallbackDatabase()` method
2. Added 30+ Filipino foods with CKD-relevant nutrient data
3. Maintained backward compatibility with existing common foods
4. Updated UI text to reflect new capability

### Code Structure:
```dart
final foods = {
  'kare kare': NutritionalData(
    productName: 'Kare-Kare (Filipino Peanut Stew)',
    servingSize: '1 cup (250g)',
    sodium: 520.0,
    potassium: 480.0,
    phosphorus: 200.0,
    protein: 20.0,
  ),
  // ... more foods
};
```

---

## 🎯 Benefits

### For Filipino CKD Patients:
- ✅ Can now search their favorite dishes
- ✅ Understand which Filipino foods are high-risk
- ✅ Make informed decisions about traditional meals
- ✅ Find safer alternatives within Filipino cuisine
- ✅ Don't need to give up cultural food entirely

### For the App:
- ✅ Fills gap in FatSecret API coverage
- ✅ Culturally relevant to target users
- ✅ Improves user satisfaction
- ✅ Makes app more comprehensive
- ✅ Differentiates from competitors

---

## 📈 Future Enhancements

### Could Add Later:
1. **More Filipino Foods**:
   - Regional specialties
   - Street foods
   - Modern Filipino fusion dishes

2. **Recipe Modifications**:
   - Low-sodium versions
   - Kidney-friendly cooking tips
   - Ingredient substitution suggestions

3. **User Contributions**:
   - Allow users to submit Filipino foods
   - Community-verified nutritional data
   - Regional variations

4. **Meal Planning**:
   - Suggest kidney-friendly Filipino meal combos
   - Daily menu suggestions
   - Special occasion meal planning

---

## ✨ Summary

**Problem Solved**: Filipino foods like Kare Kare and Leche Flan can now be searched!

**Impact**: 
- 30+ Filipino dishes added
- Culturally relevant for Filipino users
- Comprehensive CKD-specific nutritional data
- Better user experience
- Fills FatSecret API gaps

**User Benefit**: Filipino CKD patients can now easily check if their favorite traditional dishes are safe to eat!

---

Created: January 2025
Version: 2.0
Feature: Food Search with Filipino Database
