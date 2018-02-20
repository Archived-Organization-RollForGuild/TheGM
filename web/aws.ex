defmodule Thegm.AWS do
  @s3_options Application.get_env(:ex_aws, :s3)
  @bucket_name System.get_env("RFG_API_AWS_BUCKET")
  @avatar_location "avatars"

  alias Thegm.Users

  def upload_avatar(image_binary, avatar_identifier) do
    image =
      ExAws.S3.put_object(@bucket_name, "#{@avatar_location}/#{avatar_identifier}.jpg", image_binary)
      |> ExAws.request!
  end
end
