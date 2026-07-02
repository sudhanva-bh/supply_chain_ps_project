from pydantic import BaseModel, Field
from typing import List, Optional, Literal, Any

class TableViewPayload(BaseModel):
    columns: List[str]
    rows: List[List[Any]]

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
    chart_type: str
    labels: List[str]
    values: List[float]

class AgentResponse(BaseModel):
    response_type: Literal["text_only", "table_view", "metric_kpi_view", "timeline_view", "chart_view", "direct_fetch_table"]
    conversational_text: str = Field(description="Natural language summary or commentary explaining the data.")
    table_payload: Optional[TableViewPayload] = Field(None, description="Populate only if response_type is table_view")
    metric_kpi_payload: Optional[List[MetricKPIViewPayload]] = Field(None, description="Populate only if response_type is metric_kpi_view")
    timeline_payload: Optional[List[TimelineViewPayload]] = Field(None, description="Populate only if response_type is timeline_view")
    chart_payload: Optional[ChartViewPayload] = Field(None, description="Populate only if response_type is chart_view")
    direct_fetch_payload: Optional[DirectFetchTablePayload] = Field(None, description="Populate only if response_type is direct_fetch_table")
