
#include "MakeDustParticle.as";
#include "Explosion.as";

void onTick(CBlob@ this)
{
	if (this.hasTag("dead"))
	{
		MakeDustParticle(this.getPosition(), "SmallSmoke?.png");
		// still moves when dying
		this.AddForce(Vec2f(0.0f, -25.0f).RotateBy(this.getAngleDegrees()));

		CSpriteLayer@ tls = this.getSprite().getSpriteLayer("TLS");
		if (tls !is null)
		{
			tls.SetVisible(false);
		}
	}
}

void onDie(CBlob@ this)
{
	Explode(this, this.get_f32("explosive_radius"), this.get_f32("explosive_damage"));
}
