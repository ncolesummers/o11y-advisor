defmodule O11yAdvisorWeb.ErrorJSONTest do
  use O11yAdvisorWeb.ConnCase, async: true

  test "renders 404" do
    assert O11yAdvisorWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert O11yAdvisorWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
