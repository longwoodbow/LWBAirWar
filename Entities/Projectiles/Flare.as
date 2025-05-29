
void onInit(CBlob@ this)
{
	this.SetMapEdgeFlags(CBlob::map_collide_none);

	this.server_SetTimeToDie(3);
}