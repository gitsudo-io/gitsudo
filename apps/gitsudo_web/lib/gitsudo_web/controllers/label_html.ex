defmodule GitsudoWeb.LabelHTML do
  @moduledoc """
  The HTML templates for GitsudoWeb.OrganizationController
  """
  use GitsudoWeb, :html

  embed_templates "label_html/*"

  @doc """
  Renders a label form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def label_form(assigns)
end
