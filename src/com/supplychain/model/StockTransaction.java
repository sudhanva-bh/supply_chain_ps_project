package com.supplychain.model;

import org.json.JSONException;
import org.json.JSONObject;
import com.softwaretree.jdx.JDX_JSONObject;

public class StockTransaction extends JDX_JSONObject {
    public StockTransaction() { super(); }
    public StockTransaction(JSONObject jsonObject) throws JSONException { super(jsonObject); }
}
