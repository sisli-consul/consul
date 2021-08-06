require "rails_helper"

describe "Admin local census records", :admin do
  context "Index" do
    let!(:local_census_record) { create(:local_census_record) }

    scenario "Should show empty message when no local census records exists" do
      LocalCensusRecord.delete_all
      visit admin_local_census_records_path

      expect(page).to have_content("There are no local census records.")
    end

    scenario "Should show existing local census records" do
      visit admin_local_census_records_path

      expect(page).to have_content("TC Kimlik No")
      expect(page).to have_content(local_census_record.document_number)
      expect(page).to have_content(local_census_record.date_of_birth)
      expect(page).to have_content(local_census_record.postal_code)
    end

    scenario "Should show page entries info" do
      visit admin_local_census_records_path

      expect(page).to have_content("There is 1 local census record")
    end

    scenario "Should show paginator" do
      allow(LocalCensusRecord).to receive(:default_per_page).and_return(3)
      create_list(:local_census_record, 3)
      visit admin_local_census_records_path

      within ".pagination" do
        expect(page).to have_link("2")
      end
    end

    context "Search" do
      before do
        create(:local_census_record, document_number: "X66777888")
      end

      scenario "Should show matching records by document number at first visit" do
        visit admin_local_census_records_path(search: "X66777888")

        expect(page).to have_content "X66777888"
        expect(page).not_to have_content local_census_record.document_number
      end

      scenario "Should show matching records by document number" do
        visit admin_local_census_records_path

        fill_in :search, with: "X66777888"
        click_on "Search"

        expect(page).to have_content "X66777888"
        expect(page).not_to have_content local_census_record.document_number
      end
    end
  end
end
