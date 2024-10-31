import io

from .ociextirpate import extirpate
from fdk import response


def handler(ctx, data: io.BytesIO = None):

    extirpate()

    return response.Response(
        ctx, response_data='Finished extirpating',
        headers={"Content-Type": "text/plain"}
    )
