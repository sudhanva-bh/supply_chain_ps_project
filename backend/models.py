from pydantic import BaseModel, Field
from typing import List, Optional, Literal, Any, Union

class TableViewPayload(BaseModel):
    columns: List[str]
    rows: List[List[Union[str, int, float, bool, None]]]

class DirectFetchTablePayload(BaseModel):
    class_name: str = Field(description="The Gilhari class name to query, e.g. com.supplychain.model.PurchaseOrder")
    filter_clause: Optional[str] = Field(None, description="Optional SQL filter clause")
    columns: List[str] = Field(description="List of column names to display")

class MetricKPIViewPayload(BaseModel):
    title: str
    value: str
    trend: str = Field(description="E.g., 'up', 'down', 'stable', 'critical'")
    color: str = Field(description="E.g., 'green', 'red', 'gray'")

class TimelineViewPayload(BaseModel):
    timestamp: str
    title: str
    subtitle: str
    icon: str

class ChartViewPayload(BaseModel):
    chart_type: str = Field(description="'bar', 'pie', or 'line'")
    labels: List[str]
    values: List[float]

class RegionalData(BaseModel):
    region: str
    value: float
    percentage: float

class RegionalViewPayload(BaseModel):
    title: str
    regions: List[RegionalData]

class KanbanCard(BaseModel):
    id: str = Field(description="Unique identifier for the card, e.g. the PO ID or record ID")
    title: str = Field(description="Primary display text for the card. Use the most identifying info, e.g. 'PO #1234 - Acme Corp' or the order/item name")
    subtitle: str = Field(description="Secondary detail line. Include key metrics like amount, date, quantity, or status details. E.g. '$5,200 · Due 2024-03-15'")
    column: str = Field(description="Must exactly match one of the column names in the columns list")
    color: str = Field(description="E.g., 'red', 'green', 'blue', 'yellow', 'orange', 'purple'")

class KanbanViewPayload(BaseModel):
    columns: List[str] = Field(description="Ordered list of column names (e.g. ['PENDING', 'PROCESSING', 'IN_TRANSIT']). Each card's column field must exactly match one of these strings.")
    cards: List[KanbanCard] = Field(description="All cards to display. Every card must have a non-empty title and subtitle with real data from the query results.")

class FormFieldSchema(BaseModel):
    name: str
    label: str
    field_type: str = Field(description="E.g., 'text', 'number', 'dropdown'")
    default_value: str = ""
    options: Optional[List[str]] = Field(None, description="For dropdowns")

class ActionableFormViewPayload(BaseModel):
    form_title: str
    action_intent: str
    fields: List[FormFieldSchema]

class AlertAnomaly(BaseModel):
    severity: str = Field(description="'critical', 'warning', 'info'")
    title: str
    description: str
    suggested_action: str

class AlertAnomalyViewPayload(BaseModel):
    alerts: List[AlertAnomaly]

class ConfirmationViewPayload(BaseModel):
    tool_name: str = Field(description="The name of the tool to execute")
    args_json: str = Field(description="JSON string of the tool arguments")
    summary: str = Field(description="A concise summary of the action that will be performed")

class AgentResponse(BaseModel):
    response_type: Literal["text_only", "table_view", "metric_kpi_view", "timeline_view", "chart_view", "direct_fetch_table", "regional_view", "kanban_view", "actionable_form_view", "alert_anomaly_view", "confirmation_view"]
    conversational_text: str = Field(description="Natural language summary or commentary explaining the data.")
    table_payload: Optional[TableViewPayload] = Field(None, description="Populate only if response_type is table_view")
    metric_kpi_payload: Optional[List[MetricKPIViewPayload]] = Field(None, description="Populate only if response_type is metric_kpi_view")
    timeline_payload: Optional[List[TimelineViewPayload]] = Field(None, description="Populate only if response_type is timeline_view")
    chart_payload: Optional[ChartViewPayload] = Field(None, description="Populate only if response_type is chart_view")
    direct_fetch_payload: Optional[DirectFetchTablePayload] = Field(None, description="Populate only if response_type is direct_fetch_table")
    regional_payload: Optional[RegionalViewPayload] = Field(None, description="Populate only if response_type is regional_view")
    kanban_payload: Optional[KanbanViewPayload] = Field(None, description="Populate only if response_type is kanban_view")
    actionable_form_payload: Optional[ActionableFormViewPayload] = Field(None, description="Populate only if response_type is actionable_form_view")
    alert_anomaly_payload: Optional[AlertAnomalyViewPayload] = Field(None, description="Populate only if response_type is alert_anomaly_view")
    confirmation_payload: Optional[ConfirmationViewPayload] = Field(None, description="Populate only if response_type is confirmation_view")
