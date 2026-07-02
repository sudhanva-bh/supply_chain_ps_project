package com.supplychain.model;

import org.json.JSONException;
import org.json.JSONObject;
import com.softwaretree.jdx.JDX_JSONObject;

public class InventoryItem extends JDX_JSONObject {
    public InventoryItem() { super(); }
    public InventoryItem(JSONObject jsonObject) throws JSONException { super(jsonObject); }
    
    public StockTransaction[] stockTransactions;
}
