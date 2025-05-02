from datetime import datetime, timezone

import pandas as pd


def to_mysql_ts(ts):

    if ts is not None:
        sql_ts = (
            datetime.fromisoformat(ts[:-1])
            .astimezone(timezone.utc)
            .strftime("%Y-%m-%d %H:%M:%S")
        )
        return sql_ts
    else:
        return None


def update_destination_table(df: pd.DataFrame, table: str, cur) -> None:

    columns = df.columns.tolist()
    placeholders = ", ".join(["%s"] * len(columns))
    col_names = ", ".join(columns)

    for _, row in df.iterrows():
        cur.execute(
            f"""
            INSERT INTO {table} ({col_names})
            VALUES ({placeholders})
        """,
            tuple(row.values),
        )


def clear_destination_table(table: str, cur) -> None:

    cur.execute(f"TRUNCATE TABLE {table};")
