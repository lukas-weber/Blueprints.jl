module BlueprintsCarloExt

using Blueprints
using Carlo.JobTools

function Blueprints.dependencies(task::TaskInfo)
    paramdeps, paramconstructor = Blueprints.dependencies(task.params)

    function constructor(xs)
        TaskInfo(task.name, paramconstructor(xs))
    end

    return paramdeps, constructor
end

function Blueprints.dependencies(job::JobInfo)
    taskdeps, taskconstructor = Blueprints.dependencies(job.tasks)

    function constructor(xs)
        return JobInfo(
            job.name,
            job.dir,
            job.mc,
            job.rng,
            taskconstructor(xs),
            job.checkpoint_time,
            job.run_time,
            job.ranks_per_run,
        )
    end
    return taskdeps, constructor
end

end
