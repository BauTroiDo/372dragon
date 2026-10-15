"""Read only private forge evidence; no account/credential documents printed."""
from cs3b_menpai import provision
with provision().database() as c:
 for db in c.list_database_names():
  if db in ('admin','local','config'):continue
  if 'log_raw_call_function' in c[db].list_collection_names():
   for d in c[db].log_raw_call_function.find({'id':809262},{'_id':0,'func':1,'args':1,'date_time':1}).sort('_id',-1).limit(12):print(d)
 d=c.tlbb.character.find_one({'attrib.guid':200016},{'_id':0,'attrib.money':1,'attrib.jiaozi':1,'cys_forge':1,'prop_bag_list.19.enhancement_level':1,'prop_bag_list.19.status':1,'prop_bag_list.20.count':1})
 print(d)
