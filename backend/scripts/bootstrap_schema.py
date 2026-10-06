"""Create missing tables before applying versioned migrations on a clean install."""

from app.core.database import Base, engine
import app.models


def main() -> None:
    Base.metadata.create_all(bind=engine, checkfirst=True)


if __name__ == "__main__":
    main()