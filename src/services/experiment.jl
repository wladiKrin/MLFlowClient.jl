"""
    createexperiment(instance::MLFlow, name::String;
        artifact_location::String="",
        tags::Union{Dict{<:Any}, Array{<:Any}}=[])

Create an experiment with a name. Returns the newly created experiment.
Validates that another experiment with the same name does not already exist and
fails if another experiment with the same name already exists.

# Arguments
- `instance`: [`MLFlow`](@ref) configuration.
- `name`: Experiment name. This field is required.
- `artifact_location`: Location where all artifacts for the experiment
are stored. If not provided, the remote server will select an appropriate
default.
- `tags`: A collection of tags to set on the experiment.

# Returns
The ID of the newly created experiment.
"""
function createexperiment(instance::MLFlow, name::String;
    artifact_location::Union{String, Missing}=missing,
    tags::MLFlowUpsertData{Tag}=Tag[])::String
    result = mlfpost(instance, "experiments/create"; name=name,
        artifact_location=artifact_location, tags=parse(Tag, tags))
    return result["experiment_id"]
end

"""
    getexperiment(instance::MLFlow, experiment_id::String)
    getexperiment(instance::MLFlow, experiment_id::Integer)

Get metadata for an experiment. This method works on deleted experiments.

# Arguments
- `instance`: [`MLFlow`](@ref) configuration.
- `experiment_id`: ID of the associated experiment.

# Returns
An instance of type [`Experiment`](@ref).
"""
function getexperiment(instance::MLFlow, experiment_id::String)::Experiment
    result = mlfget(instance, "experiments/get"; experiment_id=experiment_id)
    return result["experiment"] |> Experiment
end
getexperiment(instance::MLFlow, experiment_id::Integer)::Experiment =
    getexperiment(instance, string(experiment_id))

"""
    getexperimentbyname(instance::MLFlow, experiment_name::String)

Get metadata for an experiment.

This endpoint will return deleted experiments, but prefers the active
experiment if an active and deleted experiment share the same name. If multiple
deleted experiments share the same name, the API will return one of them.

# Arguments
- `instance`: [`MLFlow`](@ref) configuration.
- `experiment_name`: Name of the associated experiment.

# Returns
An instance of type [`Experiment`](@ref).
"""
function getexperimentbyname(instance::MLFlow,
    experiment_name::String)::Experiment
    result = mlfget(instance, "experiments/get-by-name";
        experiment_name=experiment_name)
    return result["experiment"] |> Experiment
end

"""
    deleteexperiment(instance::MLFlow, experiment_id::String)
    deleteexperiment(instance::MLFlow, experiment_id::Integer)
    deleteexperiment(instance::MLFlow, experiment::Experiment)

Mark an experiment and associated metadata, runs, metrics, params, and tags for
deletion. If the experiment uses FileStore, artifacts associated with
experiment are also deleted.

# Arguments
- `instance`: [`MLFlow`](@ref) configuration.
- `experiment_id`: ID of the associated experiment.

# Returns
`true` if successful. Otherwise, raises exception.
"""
function deleteexperiment(instance::MLFlow, experiment_id::String)
    mlfpost(instance, "experiments/delete"; experiment_id=experiment_id)
    return true
end
deleteexperiment(instance::MLFlow, experiment_id::Integer) =
    deleteexperiment(instance, string(experiment_id))
deleteexperiment(instance::MLFlow, experiment::Experiment) =
    deleteexperiment(instance, experiment.experiment_id)

"""
    restoreexperiment(instance::MLFlow, experiment_id::String)
    restoreexperiment(instance::MLFlow, experiment_id::Integer)
    restoreexperiment(instance::MLFlow, experiment::Experiment)

Restore an experiment marked for deletion. This also restores associated
metadata, runs, metrics, params, and tags. If experiment uses FileStore,
underlying artifacts associated with experiment are also restored.

# Arguments
- `instance`: [`MLFlow`](@ref) configuration.
- `experiment_id`: ID of the associated experiment.

# Returns
`true` if successful. Otherwise, raises exception.
"""
function restoreexperiment(instance::MLFlow, experiment_id::String)
    mlfpost(instance, "experiments/restore"; experiment_id=experiment_id)
    return true
end
restoreexperiment(instance::MLFlow, experiment_id::Integer) =
    restoreexperiment(instance, string(experiment_id))
restoreexperiment(instance::MLFlow, experiment::Experiment) =
    restoreexperiment(instance, experiment.experiment_id)

"""
    updateexperiment(instance::MLFlow, experiment_id::String, new_name::String)
    updateexperiment(instance::MLFlow, experiment_id::Integer,
        new_name::String)
    updateexperiment(instance::MLFlow, experiment::Experiment,
        new_name::String)

Update experiment metadata.

# Arguments
- `instance`: [`MLFlow`](@ref) configuration.
- `experiment_id`: ID of the associated experiment.
- `new_name`: If provided, the experiment’s name is changed to the new name.
The new name must be unique.

# Returns
`true` if successful. Otherwise, raises exception.
"""
function updateexperiment(instance::MLFlow, experiment_id::String,
    new_name::String)
    mlfpost(instance, "experiments/update"; experiment_id=experiment_id,
        new_name=new_name)
    return true
end
updateexperiment(instance::MLFlow, experiment_id::Integer, new_name::String) =
    updateexperiment(instance, string(experiment_id), new_name)
updateexperiment(instance::MLFlow, experiment::Experiment, new_name::String) =
    updateexperiment(instance, experiment.experiment_id, new_name::String)

"""
    searchexperiments(instance::MLFlow; max_results::Int64=20000,
        page_token::String="", filter::String="", order_by::Array{String}=[],
        view_type::ViewType=ACTIVE_ONLY)

# Arguments
- `instance`: [`MLFlow`](@ref) configuration.
- `max_results`: Maximum number of experiments desired.
- `page_token`: Token indicating the page of experiments to fetch.
- `filter`: A filter expression over experiment attributes and tags that allows
returning a subset of experiments. See [MLFlow documentation](https://mlflow.org/docs/latest/rest-api.html#search-experiments).
- `order_by`: List of columns for ordering search results, which can include
experiment name and id with an optional “DESC” or “ASC” annotation, where “ASC”
is the default.
- `view_type`: Qualifier for type of experiments to be returned. If
unspecified, return only active experiments.

# Returns
- vector of [`MLFlowExperiment`](@ref) experiments that were found in the MLFlow instance
"""
function searchexperiments(instance::MLFlow; max_results::Int64=20000,
    page_token::String="", filter::String="", order_by::Array{String}=String[],
    view_type::ViewType=ACTIVE_ONLY
)::Tuple{Array{Experiment}, Union{String, Nothing}}
    parameters = (; max_results, page_token, filter,
        :view_type => view_type |> Integer)

    if order_by |> !isempty
        parameters = (; order_by, parameters...)
    end

    result = mlfget(instance, "experiments/search"; parameters...)

    experiments = result["experiments"] |> (x -> [Experiment(y) for y in x])
    next_page_token = get(result, "next_page_token", nothing)

    return experiments, next_page_token
end

"""
    setexperimenttag(instance::MLFlow, experiment_id::String, key::String,
        value::String)
    setexperimenttag(instance::MLFlow, experiment_id::Integer, key::String,
        value::String)
    setexperimenttag(instance::MLFlow, experiment::Experiment, key::String,
        value::String)

Set a tag on an experiment. Experiment tags are metadata that can be updated.

# Arguments
- `experiment_id`: ID of the experiment under which to log the tag.
- `key`: Name of the tag.
- `value`: String value of the tag being logged.
"""
setexperimenttag(instance::MLFlow, experiment_id::String, key::String,
    value::String) =
    mlfpost(instance, "experiments/set-experiment-tag";
        experiment_id=experiment_id, key=key, value=value)
setexperimenttag(instance::MLFlow, experiment_id::Integer, key::String,
    value::String) =
    setexperimenttag(instance, string(experiment_id), key, value)
setexperimenttag(instance::MLFlow, experiment::Experiment, key::String,
    value::String) =
    setexperimenttag(instance, experiment.experiment_id, key, value)
