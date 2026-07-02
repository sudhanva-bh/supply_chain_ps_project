package com.supplychain.model;

import org.json.JSONException;
import org.json.JSONObject;
import com.softwaretree.jdx.JDX_JSONObject;

public class ItemCategory extends JDX_JSONObject {
    public ItemCategory() { super(); }
    public ItemCategory(JSONObject jsonObject) throws JSONException { super(jsonObject); }
    
    public InventoryItem[] inventoryItems;
}
