package com.supplychain.model;

import org.json.JSONException;
import org.json.JSONObject;
import com.softwaretree.jdx.JDX_JSONObject;

public class PurchaseOrderItem extends JDX_JSONObject {
    public PurchaseOrderItem() { super(); }
    public PurchaseOrderItem(JSONObject jsonObject) throws JSONException { super(jsonObject); }
}
