package com.supplychain.model;

import org.json.JSONException;
import org.json.JSONObject;
import com.softwaretree.jdx.JDX_JSONObject;

public class PurchaseOrder extends JDX_JSONObject {
    public PurchaseOrder() { super(); }
    public PurchaseOrder(JSONObject jsonObject) throws JSONException { super(jsonObject); }
    
    public PurchaseOrderItem[] purchaseOrderItems;
}
