
#include "MakeDustParticle.as";
#include "Explosion.as";

void onTick(CBlob@ this)
{
	if (this.hasTag("dead"))
	{
		MakeDustParticle(this.getPosition() + Vec2f(0.0f, 8.0f), "SmallSmoke?.png");
		// still moves when dying
		this.AddForce(Vec2f(0.0f, -25.0f).RotateBy(this.getAngleDegrees()));

		CSpriteLayer@ tls = this.getSprite().getSpriteLayer("TLS");
		if (tls !is null)
		{
			tls.SetVisible(false);
		}
	}
}

void onGib(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	Explode(blob, blob.get_f32("explosive_radius"), blob.get_f32("explosive_damage"));
}

// moved here because it want to work even died
bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	//only collide with projectiles
	if (blob.hasTag("projectile") && this.getTeamNum() != blob.getTeamNum())
	{
		return true;
	}

	return false;
}
