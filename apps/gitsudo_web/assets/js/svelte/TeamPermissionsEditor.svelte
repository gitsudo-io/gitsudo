<script>
  import { onMount } from "svelte";

  export let org;
  export let labelid;
  export let text;
  export let teampermissions;

  let permissions = [];

  const permission_values = ["pull", "triage", "push", "maintain", "admin"];

  onMount(async () => {
    parsed = JSON.parse(teampermissions);
    a = [];
    for (const [k, v] of Object.entries(parsed)) {
      a.push({ team: k, permission: v });
    }
    permissions = a;
    console.log(permissions);
  });
</script>

<table class="table table-fixed w-full">
  <tr class="bg-base-200"
    ><th class="w-1/6">Team</th><th class="w-1/6">Permission</th><th
      class="w-4/6"
    /></tr
  >

  {#each permissions as permission}
    <tr
      ><td
        >{permission.team}
        <input
          type="hidden"
          name="team_permissions_teams[]"
          value={permission.team}
        />
      </td><td>
        <select
          name="team_permissions_permissions[]"
          value={permission.permission}
          class="select"
        >
          {#each permission_values as value}
            <option {value}>{value}</option>
          {/each}
        </select></td
      ><td><span class="hero-minus-circle" /></td></tr
    >
  {/each}
</table>
