package com.supplychain.model;

import org.json.JSONException;
import org.json.JSONObject;
import com.softwaretree.jdx.JDX_JSONObject;

public class Supplier extends JDX_JSONObject {
    public Supplier() { super(); }
    public Supplier(JSONObject jsonObject) throws JSONException { super(jsonObject); }
    
    public InventoryItem[] inventoryItems;
}
