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
    id: str
    title: str
    subtitle: str
    column: str
    color: str = Field(description="E.g., 'red', 'green', 'blue', 'yellow'")

class KanbanViewPayload(BaseModel):
    columns: List[str]
    cards: List[KanbanCard]

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
