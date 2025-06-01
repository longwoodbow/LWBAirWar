f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	CPlayer@ thisPlayer = this.getPlayer();
	CPlayer@ hitterPlayer = hitterBlob.getDamageOwnerPlayer();
	CBlob@ enemy = hitterPlayer.getBlob();
	if (enemy !is null && damage > 0.0f && thisPlayer !is hitterPlayer)
	{
		enemy.set_u32("hit_message", getGameTime() + 30);
		if (damage >= this.getHealth() * 2.0f) enemy.set_bool("destroyed_message", true);
		else enemy.set_bool("destroyed_message", false);
	}
	return damage;
}