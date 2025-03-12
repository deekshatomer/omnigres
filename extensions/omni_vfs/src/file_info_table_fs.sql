create function file_info(fs table_fs, path text) returns omni_vfs_types_v1.file_info
    stable
    language sql set search_path to omni_vfs
as
$$

with
    match(id, kind) as (
        select id, kind
        from table_fs_files
        where filename = path and filesystem_id = fs.id
    ),
    file_metadata as (
  select
    m.id,
    m.kind,
    coalesce(sum(length(d.data)), 0) as size,
    min(d.created_at) as created_at,
    max(d.accessed_at) as accessed_at,
    max(d.modified_at) as modified_at
from match m
left join table_fs_file_data d on m.id = d.file_id
group by m.id, m.kind
    )
    select
         coalesce(fm.size, 0) as size,
         fm.created_at,
         fm.accessed_at,
         fm.modified_at,
         fm.kind
from file_metadata fm
union all
select
      0 as size,
      null as created_at,
      null as accessed_at,
      null as modified_at,
       'directory' as kind  
from (value (1)) as temp(dummy)          
where path = '/';
$$;
