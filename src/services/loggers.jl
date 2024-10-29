"""
    logmetric(instance::MLFlow, run_id::String, key::String, value::Float64;
        timestamp::Int64=round(Int, now() |> datetime2unix),
        step::Union{Int64, Missing}=missing)
    logmetric(instance::MLFlow, run::Run, key::String, value::Float64;
        timestamp::Int64=round(Int, now() |> datetime2unix),
        step::Union{Int64, Missing}=missing)

Log a metric for a run. A metric is a key-value pair (string key, float value)
with an associated timestamp. Examples include the various metrics that
represent ML model accuracy. A metric can be logged multiple times.

# Arguments
- `instance`: [`MLFlow`](@ref) configuration.
- `run_id`: ID of the run under which to log the metric.
- `key`: Name of the metric.
- `value`: Double value of the metric being logged.
- `timestamp`: Unix timestamp in milliseconds at the time metric was logged.
- `step`: Step at which to log the metric.
"""
logmetric(instance::MLFlow, run_id::String, key::String, value::Float64;
    timestamp::Int64=round(Int, now() |> datetime2unix),
    step::Union{Int64, Missing}=missing) =
    mlfpost(instance, "runs/log-metric"; run_id=run_id, key=key, value=value, timestamp=timestamp, step=step)
logmetric(instance::MLFlow, run::Run, key::String, value::Float64;
    timestamp::Int64=round(Int, now() |> datetime2unix),
    step::Union{Int64, Missing}=missing) =
    logmetric(instance, run.info.run_id, key, value; timestamp=timestamp, step=step)

"""
    logbatch(instance::MLFlow, run_id::String;
        metrics::MLFlowUpsertData{Metric}, params::MLFlowUpsertData{Param},
        tags::MLFlowUpsertData{Tag})
    logbatch(instance::MLFlow, run::Run; metrics::Array{Metric},
        params::MLFlowUpsertData{Param}, tags::MLFlowUpsertData{Tag})

Log a batch of metrics, params, and tags for a run. In case of error, partial
data may be written.

For more information about this function, check [MLFlow official documentation](https://mlflow.org/docs/latest/rest-api.html#log-batch).
"""
logbatch(instance::MLFlow, run_id::String;
    metrics::MLFlowUpsertData{Metric}=Metric[],
    params::MLFlowUpsertData{Param}=Param[],
    tags::MLFlowUpsertData{Tag}=Tag[]) =
    mlfpost(instance, "runs/log-batch"; run_id=run_id,
        metrics=parse(Metric, metrics), params=parse(Param, params),
        tags=parse(Tag, tags))
logbatch(instance::MLFlow, run::Run;
    metrics::MLFlowUpsertData{Metric}=Metric[],
    params::MLFlowUpsertData{Param}=Param[],
    tags::MLFlowUpsertData{Tag}=Tag[]) =
    logbatch(instance, run.info.run_id; metrics=metrics, params=params,
        tags=tags)

"""
    loginputs(instance::MLFlow, run_id::String; datasets::Array{DatasetInput})
    loginputs(instance::MLFlow, run::Run; datasets::Array{DatasetInput})

# Arguments
- `instance`: [`MLFlow`](@ref) configuration.
- `run_id`: ID of the run to log under This field is required.
- `datasets`: Dataset inputs.
"""
loginputs(instance::MLFlow, run_id::String, datasets::Array{DatasetInput}) =
    mlfpost(instance, "runs/log-inputs"; run_id=run_id, datasets=datasets)
loginputs(instance::MLFlow, run::Run, datasets::Array{DatasetInput}) =
    loginputs(instance, run.info.run_id, datasets)
